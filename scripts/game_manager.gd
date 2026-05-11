extends Node

# =============================================
# GameManager — AutoLoad Singleton
# =============================================

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal time_changed(new_time: float)
signal level_won
signal game_over

var score:              int    = 0
var lives:              int    = 3
var current_level:      int    = 1
var selected_character: String = "white_bunny"
var levels_unlocked:    int    = 1

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

# ── Level Setup ──────────────────────────────────────────────────────────────

func start_level(level_num: int) -> void:
	current_level        = level_num
	var config: Dictionary = get_level_config(level_num)
	score                = 0
	lives                = config["lives"]
	time_remaining       = config["time_limit"]
	timer_running        = false
	_level_won_emitted   = false
	_gameover_emitted    = false
	score_changed.emit(score)
	lives_changed.emit(lives)
	time_changed.emit(time_remaining)

func get_level_config(level_num: int) -> Dictionary:
	for cfg in level_configs:
		if cfg["level"] == level_num:
			return cfg
	return level_configs[0]

# ── Score ────────────────────────────────────────────────────────────────────

func add_score(points: int) -> void:
	score += points
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
	time_remaining     = 70.0
	timer_running      = false
	_level_won_emitted = false
	_gameover_emitted  = false
