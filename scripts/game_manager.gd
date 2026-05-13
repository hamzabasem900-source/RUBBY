extends Node

# =============================================
# GameManager — AutoLoad Singleton
# =============================================

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal damage_taken(new_lives: int)
signal time_changed(new_time: float)
signal level_won
signal game_over
signal carrot_wallet_changed(new_total: int)
signal skin_collection_changed
signal selected_skin_changed(skin_id: String)

var score:              int    = 0
var lives:              int    = 3
var current_level:      int    = 1
var selected_character: String = "white_bunny"
var levels_unlocked:    int    = 1
var carrot_wallet:      int    = 0
var level_carrots_earned: int  = 0
var last_banked_carrots: int    = 0
var owned_skins: Array[String] = ["white_bunny", "brown_bunny", "dune_hare", "snow_scout"]

var level_configs: Array = [
	{
		"level": 1, "time_limit": 70.0, "lives": 3,
		"required_score": 80,  "fox_count": 1,
		"hole_count": 3, "thorn_count": 3,
		"carrot_count": 12, "golden_carrot_count": 2
	},
	{
		"level": 2, "time_limit": 55.0, "lives": 3,
		"required_score": 120, "fox_count": 2,
		"hole_count": 5, "thorn_count": 5,
		"carrot_count": 16, "golden_carrot_count": 3
	},
	{
		"level": 3, "time_limit": 45.0, "lives": 2,
		"required_score": 160, "fox_count": 3,
		"hole_count": 7, "thorn_count": 8,
		"carrot_count": 20, "golden_carrot_count": 4
	}
]

var time_remaining:      float = 70.0
var timer_running:       bool  = false
var _level_won_emitted:  bool  = false
var _gameover_emitted:   bool  = false

const SAVE_PATH: String = "user://progress.cfg"
const SAVE_SECTION: String = "progress"
const DEFAULT_SKIN_ID: String = "white_bunny"


const SKIN_CATALOG: Array[Dictionary] = [
	{
		"id": "white_bunny", "name_key": "skin_white_name", "description_key": "skin_white_desc",
		"price": 0, "icon": "🐰", "badge": "", "body_color": Color(0.95, 0.95, 0.95), "tail_color": Color(0.84, 0.84, 0.82), "icon_tint": Color(1.0, 1.0, 1.0)
	},
	{
		"id": "brown_bunny", "name_key": "skin_runner_name", "description_key": "skin_runner_desc",
		"price": 0, "icon": "🐇", "badge": "", "body_color": Color(0.58, 0.36, 0.18), "tail_color": Color(0.86, 0.70, 0.48), "icon_tint": Color(0.78, 0.50, 0.26)
	},
	{
		"id": "meadow_bunny", "name_key": "skin_meadow_name", "description_key": "skin_meadow_desc",
		"price": 12, "icon": "🐰", "badge": "🌿", "body_color": Color(0.54, 0.82, 0.42), "tail_color": Color(0.38, 0.64, 0.30)
	},
	{
		"id": "rose_bunny", "name_key": "skin_rose_name", "description_key": "skin_rose_desc",
		"price": 28, "icon": "🐰", "badge": "🌸", "body_color": Color(1.00, 0.58, 0.72), "tail_color": Color(0.88, 0.38, 0.56)
	},
	{
		"id": "golden_bunny", "name_key": "skin_golden_name", "description_key": "skin_golden_desc",
		"price": 55, "icon": "🐰", "badge": "⭐", "body_color": Color(1.00, 0.76, 0.18), "tail_color": Color(0.88, 0.56, 0.10)
	},
	{
		"id": "night_bunny", "name_key": "skin_night_name", "description_key": "skin_night_desc",
		"price": 90, "icon": "🐰", "badge": "🌙", "body_color": Color(0.20, 0.22, 0.36), "tail_color": Color(0.12, 0.14, 0.26)
	},
	{
		"id": "tiny_bunny", "name_key": "skin_tiny_name", "description_key": "skin_tiny_desc",
		"price": 120, "icon": "🐰", "badge": "🍄", "body_color": Color(0.96, 0.82, 0.48), "tail_color": Color(0.86, 0.68, 0.34),
		"visual_scale": 0.82, "icon_font_size": 62, "collision_height": 34.0, "collision_radius": 15.0, "pickup_radius": 28.0, "badge_offset": Vector2(14.0, -50.0)
	},
	{
		"id": "lop_bunny", "name_key": "skin_lop_name", "description_key": "skin_lop_desc",
		"price": 155, "icon": "🐇", "badge": "🎀", "body_color": Color(0.78, 0.78, 0.90), "tail_color": Color(0.64, 0.64, 0.80),
		"visual_scale": 1.16, "icon_font_size": 58, "collision_height": 50.0, "collision_radius": 20.0, "pickup_radius": 38.0, "badge_offset": Vector2(20.0, -66.0)
	},
	{
		"id": "spotted_bunny", "name_key": "skin_spotted_name", "description_key": "skin_spotted_desc",
		"price": 40, "icon": "🐇", "badge": "🐾", "body_color": Color(0.56, 0.34, 0.18), "tail_color": Color(0.94, 0.90, 0.82), "icon_tint": Color(0.70, 0.45, 0.25),
		"visual_scale": 1.08, "icon_font_size": 60, "collision_height": 46.0, "collision_radius": 19.0, "pickup_radius": 36.0, "badge_offset": Vector2(19.0, -63.0)
	}
]

const PLAYABLE_CHARACTER_OVERRIDES: Array[Dictionary] = [
	{
		"id": "white_bunny", "name_key": "skin_white_name", "description_key": "skin_white_desc",
		"price": 0, "icon": "🐇", "badge": "", "body_color": Color(0.95, 0.95, 0.95), "tail_color": Color(0.84, 0.84, 0.82), "icon_tint": Color(1.0, 1.0, 1.0)
	},
	{
		"id": "brown_bunny", "name_key": "skin_runner_name", "description_key": "skin_runner_desc",
		"price": 0, "icon": "🐇", "badge": "", "body_color": Color(0.58, 0.36, 0.18), "tail_color": Color(0.86, 0.70, 0.48), "icon_tint": Color(0.78, 0.50, 0.26)
	},
	{
		"id": "dune_hare", "name_key": "skin_dune_name", "description_key": "skin_dune_desc",
		"price": 0, "icon": "🐇", "badge": "⚡", "body_color": Color(0.76, 0.42, 0.12), "tail_color": Color(1.00, 0.76, 0.35), "icon_tint": Color(0.96, 0.52, 0.13),
		"visual_scale": 1.18, "icon_font_size": 62, "collision_height": 48.0, "collision_radius": 19.0, "pickup_radius": 37.0, "badge_offset": Vector2(21.0, -67.0)
	},
	{
		"id": "snow_scout", "name_key": "skin_snow_name", "description_key": "skin_snow_desc",
		"price": 0, "icon": "🐇", "badge": "❄", "body_color": Color(0.52, 0.82, 1.00), "tail_color": Color(0.86, 0.96, 1.00), "icon_tint": Color(0.58, 0.86, 1.00),
		"visual_scale": 0.92, "icon_font_size": 64, "collision_height": 37.0, "collision_radius": 16.0, "pickup_radius": 30.0, "badge_offset": Vector2(15.0, -54.0)
	}
]

func _ready() -> void:
	load_progress()

# ── Skins / Shop ─────────────────────────────────────────────────────────────

func get_skin_catalog() -> Array[Dictionary]:
	var unique_catalog: Array[Dictionary] = []
	var seen_ids: Array[String] = []
	for skin in SKIN_CATALOG:
		var skin_id := str(skin["id"])
		if seen_ids.has(skin_id):
			continue
		seen_ids.append(skin_id)
		unique_catalog.append(skin.duplicate(true))
	return unique_catalog

func get_skin_data(skin_id: String) -> Dictionary:
	return _get_playable_skin_data(skin_id).duplicate(true)

func get_selected_skin_data() -> Dictionary:
	return get_skin_data(selected_character)

func _get_playable_skin_data(skin_id: String) -> Dictionary:
	for skin in PLAYABLE_CHARACTER_OVERRIDES:
		if str(skin["id"]) == skin_id:
			return skin
	return _get_base_skin_data(skin_id)

func _get_base_skin_data(skin_id: String) -> Dictionary:
	for skin in SKIN_CATALOG:
		if str(skin["id"]) == skin_id:
			return skin
	return SKIN_CATALOG[0]

func is_skin_owned(skin_id: String) -> bool:
	return owned_skins.has(skin_id)

func can_afford_skin(skin_id: String) -> bool:
	var skin := _get_base_skin_data(skin_id)
	return carrot_wallet >= int(skin.get("price", 0))

func purchase_skin(skin_id: String) -> bool:
	if is_skin_owned(skin_id):
		return equip_skin(skin_id)
	var skin := _get_base_skin_data(skin_id)
	var price := int(skin.get("price", 0))
	if carrot_wallet < price:
		return false
	carrot_wallet -= price
	owned_skins.append(skin_id)
	selected_character = skin_id
	save_progress()
	carrot_wallet_changed.emit(carrot_wallet)
	skin_collection_changed.emit()
	selected_skin_changed.emit(selected_character)
	return true

func equip_skin(skin_id: String) -> bool:
	if not is_skin_owned(skin_id):
		return false
	selected_character = skin_id
	save_progress()
	skin_collection_changed.emit()
	selected_skin_changed.emit(selected_character)
	return true

func _sanitize_owned_skins(raw_value: Variant) -> Array[String]:
	var sanitized: Array[String] = []
	if raw_value is Array:
		for skin_id in raw_value:
			var array_id := str(skin_id)
			if not sanitized.has(array_id):
				sanitized.append(array_id)
	elif raw_value is PackedStringArray:
		for skin_id in raw_value:
			var packed_id := str(skin_id)
			if not sanitized.has(packed_id):
				sanitized.append(packed_id)
	if not sanitized.has(DEFAULT_SKIN_ID):
		sanitized.append(DEFAULT_SKIN_ID)
	for starter_skin in ["brown_bunny", "dune_hare", "snow_scout"]:
		if not sanitized.has(starter_skin):
			sanitized.append(starter_skin)
	return sanitized



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
	damage_taken.emit(lives)
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
	owned_skins = _sanitize_owned_skins(config.get_value(SAVE_SECTION, "owned_skins", owned_skins))
	selected_character = str(config.get_value(SAVE_SECTION, "selected_character", selected_character))
	if not is_skin_owned(selected_character):
		selected_character = DEFAULT_SKIN_ID
	carrot_wallet_changed.emit(carrot_wallet)
	skin_collection_changed.emit()
	selected_skin_changed.emit(selected_character)

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, "carrot_wallet", carrot_wallet)
	config.set_value(SAVE_SECTION, "levels_unlocked", levels_unlocked)
	config.set_value(SAVE_SECTION, "selected_character", selected_character)
	config.set_value(SAVE_SECTION, "owned_skins", owned_skins)
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
	selected_character = DEFAULT_SKIN_ID
	owned_skins = [DEFAULT_SKIN_ID, "brown_bunny", "dune_hare", "snow_scout"]
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
	skin_collection_changed.emit()
	selected_skin_changed.emit(selected_character)
