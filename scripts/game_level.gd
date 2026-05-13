extends Node2D

# =============================================
# GameLevel — Main Gameplay Controller
# Spawns objects, handles win/gameover transitions
# =============================================

const SCENE_WIN:      String = "res://scenes/WinScreen.tscn"
const SCENE_GAMEOVER: String = "res://scenes/GameOver.tscn"

const CARROT_SCENE: String = "res://scenes/Carrot.tscn"
const FOX_SCENE:    String = "res://scenes/Fox.tscn"
const HOLE_SCENE:   String = "res://scenes/Hole.tscn"
const THORN_SCENE:  String = "res://scenes/Thorn.tscn"

# Safe play area (inside border walls)
const AREA_MIN := Vector2(96.0,  105.0)
const AREA_MAX := Vector2(928.0, 640.0)

var transitioning: bool = false
var _pause_layer: CanvasLayer
var _pause_overlay: Control
var _pause_button: Button
var _damage_layer: CanvasLayer
var _damage_overlay: ColorRect
var _damage_timer: float = 0.0
var _base_position: Vector2 = Vector2.ZERO
var _used_spawn_positions: Array[Vector2] = []
var _level_carrot_slots: Array[Vector2] = []
var _level_one_spawning: bool = false

@onready var background: Sprite2D = $Background

const DAMAGE_EFFECT_DURATION: float = 1.2
const DAMAGE_SHAKE_STRENGTH: float = 15.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base_position = position
	_fit_background_to_viewport()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	GameManager.level_won.connect(_on_level_won)
	GameManager.game_over.connect(_on_game_over)
	GameManager.damage_taken.connect(_on_damage_taken)
	GameManager.timer_running = true
	AudioManager.play_gameplay_music()
	_spawn_all()
	_build_damage_effect()
	_build_pause_menu()

func _on_viewport_size_changed() -> void:
	_fit_background_to_viewport()

func _fit_background_to_viewport() -> void:
	if background == null or background.texture == null:
		return
	var viewport_size := get_viewport_rect().size
	var texture_size := background.texture.get_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var cover_scale: float = max(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	background.position = viewport_size * 0.5
	background.scale = Vector2(cover_scale, cover_scale)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if not transitioning:
		GameManager.tick_timer(delta)
	_update_damage_effect(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or _is_escape_key(event):
		if get_tree().paused and _pause_overlay != null and _pause_overlay.visible:
			_resume_game()
		else:
			_open_pause_menu()

func _is_escape_key(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE

func _exit_tree() -> void:
	position = _base_position
	get_tree().paused = false


# ── Damage Feedback ──────────────────────────────────────────────────────────

func _build_damage_effect() -> void:
	_damage_layer = CanvasLayer.new()
	_damage_layer.name = "DamageLayer"
	_damage_layer.layer = 45
	_damage_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_damage_layer)

	_damage_overlay = ColorRect.new()
	_damage_overlay.name = "RedDamageFlash"
	_damage_overlay.visible = false
	_damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
	_damage_layer.add_child(_damage_overlay)

func _on_damage_taken(_new_lives: int) -> void:
	_damage_timer = DAMAGE_EFFECT_DURATION
	if _damage_overlay != null:
		_damage_overlay.visible = true
		_damage_overlay.color = Color(1.0, 0.02, 0.0, 0.42)

func _update_damage_effect(delta: float) -> void:
	if _damage_timer <= 0.0:
		return
	_damage_timer = max(0.0, _damage_timer - delta)
	var fade := _damage_timer / DAMAGE_EFFECT_DURATION
	var pulse := 0.75 + sin(Time.get_ticks_msec() * 0.045) * 0.25
	if _damage_overlay != null:
		_damage_overlay.color = Color(1.0, 0.0, 0.0, 0.46 * fade * pulse)
		_damage_overlay.visible = _damage_timer > 0.0

	if _damage_timer > 0.0:
		var strength := DAMAGE_SHAKE_STRENGTH * fade
		position = _base_position + Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
	else:
		position = _base_position

# ── Pause Menu ────────────────────────────────────────────────────────────────

func _build_pause_menu() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.name = "PauseLayer"
	_pause_layer.layer = 50
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)

	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "☰"
	_pause_button.tooltip_text = SettingsManager.text("pause_button_hint")
	_pause_button.custom_minimum_size = Vector2(58, 52)
	_pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pause_button.offset_left = -78
	_pause_button.offset_top = 96
	_pause_button.offset_right = -20
	_pause_button.offset_bottom = 148
	_pause_button.add_theme_font_size_override("font_size", 28)
	SettingsManager.style_wooden_button(_pause_button)
	_pause_button.pressed.connect(_open_pause_menu)
	_pause_layer.add_child(_pause_button)

	_pause_overlay = Control.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.visible = false
	_pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_layer.add_child(_pause_overlay)

	var dim := ColorRect.new()
	dim.name = "Dimmer"
	dim.color = Color(0.0, 0.0, 0.0, 0.52)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 430)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := Label.new()
	title.text = SettingsManager.text("pause_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.96, 0.68, 1.0))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = SettingsManager.text("pause_subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85, 1.0))
	box.add_child(subtitle)

	box.add_child(_pause_menu_button("pause_resume", Color(0.62, 0.94, 0.56, 1.0), _resume_game))
	box.add_child(_pause_menu_button("pause_restart", Color(1.0, 0.76, 0.35, 1.0), _restart_level))
	box.add_child(_pause_menu_button("pause_lobby", Color(0.60, 0.84, 1.0, 1.0), _go_to_lobby))
	box.add_child(_pause_menu_button("pause_quit", Color(1.0, 0.48, 0.48, 1.0), _quit_game))

func _pause_menu_button(text_key: String, font_color: Color, callback: Callable) -> Button:
	var button := Button.new()
	button.text = SettingsManager.text(text_key)
	button.custom_minimum_size = Vector2(320, 56)
	button.add_theme_font_size_override("font_size", 24)
	SettingsManager.style_wooden_button(button, font_color)
	button.pressed.connect(callback)
	return button

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.16, 0.07, 0.97)
	style.border_color = Color(0.78, 0.95, 0.42, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(26)
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 16
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	return style

func _open_pause_menu() -> void:
	if transitioning or get_tree().paused:
		return
	AudioManager.play_button_click()
	_pause_button.visible = false
	_pause_overlay.visible = true
	get_tree().paused = true

func _resume_game() -> void:
	if _pause_overlay == null or not _pause_overlay.visible:
		return
	AudioManager.play_button_click()
	get_tree().paused = false
	_pause_overlay.visible = false
	_pause_button.visible = true

func _restart_level() -> void:
	AudioManager.play_button_click()
	get_tree().paused = false
	GameManager.start_level(GameManager.current_level)
	get_tree().reload_current_scene()

func _go_to_lobby() -> void:
	AudioManager.play_button_click()
	get_tree().paused = false
	GameManager.timer_running = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _quit_game() -> void:
	AudioManager.play_button_click()
	get_tree().paused = false
	get_tree().quit()

# ── Spawning ─────────────────────────────────────────────────────────────────

func _spawn_all() -> void:
	var config: Dictionary = GameManager.get_level_config(GameManager.current_level)
	_used_spawn_positions.clear()
	_level_one_spawning = GameManager.current_level == 1 and bool(config.get("organized_carrots", false))
	_level_carrot_slots.clear()
	if _level_one_spawning:
		_level_carrot_slots = _build_level_one_carrot_slots()

	# Keep centre clear for player start
	_used_spawn_positions.append(Vector2(512, 380))

	for _i in range(config["carrot_count"]):
		_spawn(CARROT_SCENE, _used_spawn_positions, false)

	for _i in range(config["golden_carrot_count"]):
		_spawn(CARROT_SCENE, _used_spawn_positions, true)

	for _i in range(config["hole_count"]):
		_spawn_hazard(HOLE_SCENE, _used_spawn_positions, true)

	for _i in range(config["thorn_count"]):
		_spawn_hazard(THORN_SCENE, _used_spawn_positions, false)

	for fox_index in range(config["fox_count"]):
		_spawn_fox(_used_spawn_positions, fox_index)

func _build_level_one_carrot_slots() -> Array[Vector2]:
	var slots: Array[Vector2] = []
	var columns := [150.0, 280.0, 410.0, 540.0, 670.0, 800.0, 900.0]
	var rows := [155.0, 275.0, 505.0, 615.0]
	for row_index in range(rows.size()):
		for column_index in range(columns.size()):
			var stagger := 36.0 if row_index % 2 == 1 else 0.0
			slots.append(Vector2(min(columns[column_index] + stagger, AREA_MAX.x), rows[row_index]))
	slots.shuffle()
	return slots

func _random_pos(used: Array, min_dist: float = 55.0) -> Vector2:
	var pos := Vector2.ZERO
	for _attempt in range(120):
		pos = Vector2(
			randf_range(AREA_MIN.x, AREA_MAX.x),
			randf_range(AREA_MIN.y, AREA_MAX.y)
		)
		var ok := true
		for u in used:
			if pos.distance_to(u) < min_dist:
				ok = false
				break
		if ok:
			break
	used.append(pos)
	return pos

func _level_one_carrot_pos(used: Array, min_dist: float) -> Vector2:
	for slot in _level_carrot_slots:
		var ok := true
		for u in used:
			if slot.distance_to(u) < min_dist:
				ok = false
				break
		if ok:
			used.append(slot)
			return slot
	return _random_pos(used, min_dist)

func _forget_spawn_position(pos: Vector2) -> void:
	for index in range(_used_spawn_positions.size() - 1, -1, -1):
		if _used_spawn_positions[index].distance_to(pos) < 4.0:
			_used_spawn_positions.remove_at(index)
			return

func _on_carrot_collected_for_respawn(is_golden: bool, old_position: Vector2) -> void:
	if not _level_one_spawning or transitioning:
		return
	_forget_spawn_position(old_position)
	var config: Dictionary = GameManager.get_level_config(GameManager.current_level)
	await get_tree().create_timer(float(config.get("carrot_respawn_delay", 3.0))).timeout
	if not is_inside_tree() or transitioning or GameManager.current_level != 1:
		return
	_spawn(CARROT_SCENE, _used_spawn_positions, is_golden)

func _spawn(scene_path: String, used: Array, golden: bool) -> void:
	if not ResourceLoader.exists(scene_path):
		push_warning("GameLevel: scene not found — " + scene_path)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_warning("GameLevel: failed to load — " + scene_path)
		return
	var obj := packed.instantiate()
	add_child(obj)
	obj.scale = Vector2(1.2, 1.2)
	var config: Dictionary = GameManager.get_level_config(GameManager.current_level)
	var carrot_min_dist := float(config.get("carrot_min_dist", 55.0))
	obj.global_position = _level_one_carrot_pos(used, carrot_min_dist) if _level_one_spawning else _random_pos(used, carrot_min_dist)
	# Property setter handles the colour update
	if "is_golden" in obj:
		obj.is_golden = golden
	if _level_one_spawning and obj.has_signal("collected_for_respawn"):
		obj.collected_for_respawn.connect(_on_carrot_collected_for_respawn)

func _spawn_hazard(scene_path: String, used: Array, is_hole: bool) -> void:
	if not ResourceLoader.exists(scene_path):
		push_warning("GameLevel: scene not found — " + scene_path)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_warning("GameLevel: failed to load — " + scene_path)
		return
	var obj := packed.instantiate()
	add_child(obj)
	obj.scale = Vector2(1.18, 1.18)
	var config: Dictionary = GameManager.get_level_config(GameManager.current_level)
	obj.global_position = _random_pos(used, float(config.get("hazard_min_dist", 60.0)))
	# Property setter handles the colour update
	if "is_hole" in obj:
		obj.is_hole = is_hole

func _spawn_fox(used: Array, fox_index: int = 0) -> void:
	if not ResourceLoader.exists(FOX_SCENE):
		push_warning("GameLevel: Fox scene not found")
		return
	var packed := load(FOX_SCENE) as PackedScene
	if packed == null:
		return
	var fox := packed.instantiate()
	add_child(fox)
	fox.scale = Vector2(1.08, 1.08)
	var config: Dictionary = GameManager.get_level_config(GameManager.current_level)
	fox.global_position = _random_pos(used, float(config.get("fox_min_dist", 100.0)))
	if "patrol_distance" in fox:
		fox.patrol_distance = randf_range(100.0, 190.0)
	if "move_right_first" in fox:
		fox.move_right_first = fox_index % 2 == 0
	var fox_count: int = int(config.get("fox_count", 1))
	if fox_count < 1:
		fox_count = 1
	var side: float = -1.0 if fox_index % 2 == 0 else 1.0
	if "chase_flank_angle" in fox:
		fox.chase_flank_angle = (TAU / fox_count) * fox_index
	if "chase_flank_side" in fox:
		fox.chase_flank_side = side
	if "chase_flank_distance" in fox:
		fox.chase_flank_distance = 75.0 if GameManager.current_level == 1 else 55.0
	if "chase_lead_distance" in fox:
		fox.chase_lead_distance = 0.0
	if "chase_weave_strength" in fox:
		fox.chase_weave_strength = 8.0 if GameManager.current_level == 1 else 5.0
	if "chase_weave_phase" in fox:
		fox.chase_weave_phase = float(fox_index) * PI
	if "separation_distance" in fox:
		fox.separation_distance = 95.0 if GameManager.current_level == 1 else 75.0
	if "separation_strength" in fox:
		fox.separation_strength = 150.0 if GameManager.current_level == 1 else 130.0
	if "chase_speed" in fox and GameManager.current_level == 1:
		fox.chase_speed = 136.0 + float(fox_index % 2) * 24.0

# ── Transitions ───────────────────────────────────────────────────────────────

func _on_level_won() -> void:
	if transitioning:
		return
	get_tree().paused = false
	transitioning = true
	GameManager.timer_running = false
	GameManager.unlock_next_level()
	AudioManager.play_win()
	await get_tree().create_timer(0.9).timeout
	get_tree().change_scene_to_file(SCENE_WIN)

func _on_game_over() -> void:
	if transitioning:
		return
	get_tree().paused = false
	transitioning = true
	GameManager.timer_running = false
	AudioManager.play_game_over()
	await get_tree().create_timer(0.9).timeout
	get_tree().change_scene_to_file(SCENE_GAMEOVER)
