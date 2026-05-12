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
signal skin_colors_changed
signal selected_skin_changed(skin_id: String)

var score:              int    = 0
var lives:              int    = 3
var current_level:      int    = 1
var selected_character: String = "white_bunny"
var levels_unlocked:    int    = 1
var carrot_wallet:      int    = 0
var level_carrots_earned: int  = 0
var last_banked_carrots: int    = 0
var owned_skins: Array[String] = ["white_bunny", "brown_bunny"]
var owned_skin_colors: Dictionary = {"white_bunny": ["white"], "brown_bunny": ["white"]}
var selected_skin_colors: Dictionary = {"white_bunny": "white", "brown_bunny": "white"}

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

const DEFAULT_COLOR_ID: String = "white"
const COLOR_VARIANTS: Array[Dictionary] = [
	{
		"id": "white", "name_key": "color_white", "price": 0,
		"body_color": Color(0.95, 0.95, 0.95), "tail_color": Color(0.84, 0.84, 0.82)
	},
	{
		"id": "honey", "name_key": "color_honey", "price": 16,
		"body_color": Color(1.00, 0.70, 0.28), "tail_color": Color(0.88, 0.52, 0.16)
	},
	{
		"id": "rose", "name_key": "color_rose", "price": 24,
		"body_color": Color(1.00, 0.58, 0.72), "tail_color": Color(0.88, 0.38, 0.56)
	},
	{
		"id": "mint", "name_key": "color_mint", "price": 32,
		"body_color": Color(0.54, 0.82, 0.42), "tail_color": Color(0.38, 0.64, 0.30)
	}
]


const SKIN_CATALOG: Array[Dictionary] = [
	{
		"id": "white_bunny", "name_key": "skin_white_name", "description_key": "skin_white_desc",
		"price": 0, "icon": "🐰", "badge": "", "body_color": Color(0.95, 0.95, 0.95), "tail_color": Color(0.84, 0.84, 0.82)
	},
	{
		"id": "brown_bunny", "name_key": "skin_runner_name", "description_key": "skin_runner_desc",
		"price": 0, "icon": "🐇", "badge": "", "body_color": Color(0.95, 0.95, 0.95), "tail_color": Color(0.84, 0.84, 0.82)
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
	}
]

func _ready() -> void:
	load_progress()

# ── Skins / Shop ─────────────────────────────────────────────────────────────

func get_skin_catalog() -> Array[Dictionary]:
	return SKIN_CATALOG.duplicate(true)

func get_color_variants(_skin_id: String = "") -> Array[Dictionary]:
	return COLOR_VARIANTS.duplicate(true)

func get_skin_data(skin_id: String) -> Dictionary:
	return get_skin_preview_data(skin_id, get_selected_color_id(skin_id))

func get_skin_preview_data(skin_id: String, color_id: String) -> Dictionary:
	var skin := _get_base_skin_data(skin_id).duplicate(true)
	_apply_color_to_skin(skin, color_id)
	return skin

func get_selected_skin_data() -> Dictionary:
	return get_skin_data(selected_character)

func _get_base_skin_data(skin_id: String) -> Dictionary:
	for skin in SKIN_CATALOG:
		if str(skin["id"]) == skin_id:
			return skin
	return SKIN_CATALOG[0]

func _apply_color_to_skin(skin: Dictionary, color_id: String) -> void:
	var color := get_color_variant(color_id)
	skin["body_color"] = color["body_color"]
	skin["tail_color"] = color["tail_color"]
	skin["color_id"] = str(color["id"])
	skin["color_name_key"] = str(color["name_key"])

func get_color_variant(color_id: String) -> Dictionary:
	for color in COLOR_VARIANTS:
		if str(color["id"]) == color_id:
			return color
	return COLOR_VARIANTS[0]

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
	_ensure_skin_color_state(skin_id)
	selected_character = skin_id
	save_progress()
	carrot_wallet_changed.emit(carrot_wallet)
	skin_collection_changed.emit()
	skin_colors_changed.emit()
	selected_skin_changed.emit(selected_character)
	return true

func equip_skin(skin_id: String) -> bool:
	if not is_skin_owned(skin_id):
		return false
	_ensure_skin_color_state(skin_id)
	selected_character = skin_id
	save_progress()
	skin_collection_changed.emit()
	skin_colors_changed.emit()
	selected_skin_changed.emit(selected_character)
	return true

func get_selected_color_id(skin_id: String) -> String:
	_ensure_skin_color_state(skin_id)
	return str(selected_skin_colors.get(skin_id, DEFAULT_COLOR_ID))

func is_skin_color_owned(skin_id: String, color_id: String) -> bool:
	_ensure_skin_color_state(skin_id)
	var owned_colors: Array = owned_skin_colors.get(skin_id, [DEFAULT_COLOR_ID])
	return owned_colors.has(color_id)

func can_afford_skin_color(color_id: String) -> bool:
	var color := get_color_variant(color_id)
	return carrot_wallet >= int(color.get("price", 0))

func purchase_or_equip_skin_color(skin_id: String, color_id: String) -> bool:
	if not is_skin_owned(skin_id):
		return false
	_ensure_skin_color_state(skin_id)
	if is_skin_color_owned(skin_id, color_id):
		return equip_skin_color(skin_id, color_id)
	var color := get_color_variant(color_id)
	var price := int(color.get("price", 0))
	if carrot_wallet < price:
		return false
	carrot_wallet -= price
	var owned_colors: Array = owned_skin_colors.get(skin_id, [DEFAULT_COLOR_ID])
	owned_colors.append(color_id)
	owned_skin_colors[skin_id] = owned_colors
	return equip_skin_color(skin_id, color_id)

func equip_skin_color(skin_id: String, color_id: String) -> bool:
	if not is_skin_owned(skin_id) or not is_skin_color_owned(skin_id, color_id):
		return false
	selected_skin_colors[skin_id] = color_id
	selected_character = skin_id
	save_progress()
	carrot_wallet_changed.emit(carrot_wallet)
	skin_colors_changed.emit()
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
	if not sanitized.has("brown_bunny"):
		sanitized.append("brown_bunny")
	return sanitized

func _ensure_skin_color_state(skin_id: String) -> void:
	if not owned_skin_colors.has(skin_id):
		owned_skin_colors[skin_id] = [DEFAULT_COLOR_ID]
	var owned_colors: Array = owned_skin_colors.get(skin_id, [DEFAULT_COLOR_ID])
	if not owned_colors.has(DEFAULT_COLOR_ID):
		owned_colors.append(DEFAULT_COLOR_ID)
	owned_skin_colors[skin_id] = owned_colors
	if not selected_skin_colors.has(skin_id):
		selected_skin_colors[skin_id] = DEFAULT_COLOR_ID
	if not owned_colors.has(str(selected_skin_colors[skin_id])):
		selected_skin_colors[skin_id] = DEFAULT_COLOR_ID

func _sanitize_owned_skin_colors(raw_value: Variant) -> Dictionary:
	var sanitized: Dictionary = {}
	if raw_value is Dictionary:
		for skin_id in raw_value.keys():
			var colors: Array = []
			var raw_colors = raw_value[skin_id]
			if raw_colors is Array or raw_colors is PackedStringArray:
				for color_id in raw_colors:
					var clean_id := str(color_id)
					if _color_variant_exists(clean_id) and not colors.has(clean_id):
						colors.append(clean_id)
			if not colors.has(DEFAULT_COLOR_ID):
				colors.append(DEFAULT_COLOR_ID)
			sanitized[str(skin_id)] = colors
	for skin_id in owned_skins:
		if not sanitized.has(skin_id):
			sanitized[skin_id] = [DEFAULT_COLOR_ID]
	return sanitized

func _sanitize_selected_skin_colors(raw_value: Variant) -> Dictionary:
	var sanitized: Dictionary = {}
	if raw_value is Dictionary:
		for skin_id in raw_value.keys():
			var color_id := str(raw_value[skin_id])
			sanitized[str(skin_id)] = color_id if _color_variant_exists(color_id) else DEFAULT_COLOR_ID
	for skin_id in owned_skins:
		if not sanitized.has(skin_id):
			sanitized[skin_id] = DEFAULT_COLOR_ID
	return sanitized

func _color_variant_exists(color_id: String) -> bool:
	for color in COLOR_VARIANTS:
		if str(color["id"]) == color_id:
			return true
	return false

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
	owned_skin_colors = _sanitize_owned_skin_colors(config.get_value(SAVE_SECTION, "owned_skin_colors", owned_skin_colors))
	selected_skin_colors = _sanitize_selected_skin_colors(config.get_value(SAVE_SECTION, "selected_skin_colors", selected_skin_colors))
	selected_character = str(config.get_value(SAVE_SECTION, "selected_character", selected_character))
	if not is_skin_owned(selected_character):
		selected_character = DEFAULT_SKIN_ID
	carrot_wallet_changed.emit(carrot_wallet)
	skin_collection_changed.emit()
	skin_colors_changed.emit()
	selected_skin_changed.emit(selected_character)

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, "carrot_wallet", carrot_wallet)
	config.set_value(SAVE_SECTION, "levels_unlocked", levels_unlocked)
	config.set_value(SAVE_SECTION, "selected_character", selected_character)
	config.set_value(SAVE_SECTION, "owned_skins", owned_skins)
	config.set_value(SAVE_SECTION, "owned_skin_colors", owned_skin_colors)
	config.set_value(SAVE_SECTION, "selected_skin_colors", selected_skin_colors)
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
	owned_skins = [DEFAULT_SKIN_ID, "brown_bunny"]
	owned_skin_colors = {DEFAULT_SKIN_ID: [DEFAULT_COLOR_ID], "brown_bunny": [DEFAULT_COLOR_ID]}
	selected_skin_colors = {DEFAULT_SKIN_ID: DEFAULT_COLOR_ID, "brown_bunny": DEFAULT_COLOR_ID}
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
	skin_colors_changed.emit()
	selected_skin_changed.emit(selected_character)
