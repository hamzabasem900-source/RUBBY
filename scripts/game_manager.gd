extends Node

# =============================================
# GameManager — AutoLoad Singleton
# =============================================

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal time_changed(new_time: float)
signal level_won
signal game_over
signal carrot_wallet_changed(new_total: int)

var score:              int    = 0
var lives:              int    = 3
var current_level:      int    = 1
var selected_character: String = "white_bunny"
var levels_unlocked:    int    = 1
var carrot_wallet:      int    = 0
var level_carrots_earned: int  = 0
var last_banked_carrots: int    = 0

var level_configs: Array = [
	{
		"level": 1, "time_limit": 70.0, "lives": 3,
		"required_score": 80,  "fox_count": 1,
		"hole_count": 3, "thorn_count": 2,
		"carrot_count": 12, "golden_carrot_count": 2
	},
	{
		"level": 2, "time_limit": 55.0, "lives": 3,
		"required_score": 120, "fox_count": 2,
		"hole_count": 5, "thorn_count": 4,
		"carrot_count": 16, "golden_carrot_count": 3
	},
	{
		"level": 3, "time_limit": 45.0, "lives": 2,
		"required_score": 160, "fox_count": 3,
		"hole_count": 7, "thorn_count": 6,
		"carrot_count": 20, "golden_carrot_count": 4
	}
]

var time_remaining:      float = 70.0
var timer_running:       bool  = false
var _level_won_emitted:  bool  = false
var _gameover_emitted:   bool  = false

const SAVE_PATH: String = "user://progress.cfg"
const SAVE_SECTION: String = "progress"

func _ready() -> void:
	load_progress()

# ── Level Setup ──────────────────────────────────────────────────────────────

func start_level(level_num: int) -> void:
	current_level        = level_num
	var config: Dictionary = get_level_config(level_num)
	score                = 0
	level_carrots_earned = 0
	last_banked_carrots  = 0
	lives                = config["lives"]
	time_remaining       = config["time_limit"]
	timer_running        = false
	_level_won_emitted   = false
	_gameover_emitted    = false
	score_changed.emit(score)
	lives_changed.emit(lives)
	time_changed.emit(time_remaining)

func get_level_config(level_num: int) -> Dictionary:
	var selected_config: Dictionary = level_configs[0]
	for cfg in level_configs:
		if cfg["level"] == level_num:
			selected_config = cfg
			break
	return _apply_difficulty(selected_config)

func _apply_difficulty(config: Dictionary) -> Dictionary:
	var adjusted := config.duplicate(true)
	var difficulty := "Normal"
	if get_node_or_null("/root/SettingsManager") != null:
		difficulty = str(SettingsManager.get_setting("difficulty"))
	match difficulty:
		"Easy":
			adjusted["time_limit"] = float(adjusted["time_limit"]) + 15.0
			adjusted["lives"] = int(adjusted["lives"]) + 1
			adjusted["required_score"] = int(float(adjusted["required_score"]) * 0.85)
		"Hard":
			adjusted["time_limit"] = max(25.0, float(adjusted["time_limit"]) - 10.0)
			adjusted["lives"] = max(1, int(adjusted["lives"]) - 1)
			adjusted["required_score"] = int(float(adjusted["required_score"]) * 1.15)
	return adjusted

# ── Score ────────────────────────────────────────────────────────────────────

func add_score(points: int, carrot_currency: int = 1) -> void:
	score += points
	level_carrots_earned += max(carrot_currency, 0)
	score_changed.emit(score)
	var config: Dictionary = get_level_config(current_level)
	if score >= config["required_score"] and not _level_won_emitted:
		_level_won_emitted = true
		level_won.emit()

# ── Lives ────────────────────────────────────────────────────────────────────

func lose_life() -> void:
	if _gameover_emitted or _level_won_emitted:
		return
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		_gameover_emitted = true
		game_over.emit()

# ── Timer ────────────────────────────────────────────────────────────────────

func tick_timer(delta: float) -> void:
	if not timer_running:
		return
	if _level_won_emitted or _gameover_emitted:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		time_changed.emit(time_remaining)
		var config: Dictionary = get_level_config(current_level)
		if score >= config["required_score"]:
			if not _level_won_emitted:
				_level_won_emitted = true
				level_won.emit()
		else:
			if not _gameover_emitted:
				_gameover_emitted = true
				game_over.emit()
	else:
		time_changed.emit(time_remaining)

# ── Progression ──────────────────────────────────────────────────────────────

func unlock_next_level() -> void:
	var next: int = current_level + 1
	if next > levels_unlocked and next <= level_configs.size():
		levels_unlocked = next
	bank_level_carrots()
	save_progress()

func bank_level_carrots() -> void:
	last_banked_carrots = level_carrots_earned
	if level_carrots_earned <= 0:
		return
	carrot_wallet += level_carrots_earned
	level_carrots_earned = 0
	carrot_wallet_changed.emit(carrot_wallet)

func load_progress() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return
	carrot_wallet = int(config.get_value(SAVE_SECTION, "carrot_wallet", 0))
	levels_unlocked = int(config.get_value(SAVE_SECTION, "levels_unlocked", levels_unlocked))
	selected_character = str(config.get_value(SAVE_SECTION, "selected_character", selected_character))
	carrot_wallet_changed.emit(carrot_wallet)

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, "carrot_wallet", carrot_wallet)
	config.set_value(SAVE_SECTION, "levels_unlocked", levels_unlocked)
	config.set_value(SAVE_SECTION, "selected_character", selected_character)
	var err := config.save(SAVE_PATH)
	if err != OK:
		push_warning("GameManager: could not save progress file.")

func get_star_rating() -> int:
	var config: Dictionary = get_level_config(current_level)
	var req: int = config["required_score"]
	if score >= int(req * 1.5):
		return 3
	elif score >= int(req * 1.1):
		return 2
	else:
		return 1

# ── Full Reset ───────────────────────────────────────────────────────────────

func reset_game() -> void:
	score              = 0
	lives              = 3
	current_level      = 1
	selected_character = "white_bunny"
	levels_unlocked    = 1
	carrot_wallet      = 0
	level_carrots_earned = 0
	last_banked_carrots = 0
	time_remaining     = 70.0
	timer_running      = false
	_level_won_emitted = false
	_gameover_emitted  = false
	save_progress()
	carrot_wallet_changed.emit(carrot_wallet)
