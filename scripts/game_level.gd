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
var _atmosphere_layer: CanvasLayer
var _ambient_layer: Node2D
var _ambient_items: Array[Dictionary] = []
var _sun_rays: Array[Line2D] = []

@onready var background: Sprite2D = $Background

const DAMAGE_EFFECT_DURATION: float = 1.2
const DAMAGE_SHAKE_STRENGTH: float = 15.0
const AMBIENT_ICONS: Array[String] = ["🍃", "✦", "✧", "🌿", "❀"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base_position = position
	_fit_background_to_viewport()
	_build_level_atmosphere()
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
	_layout_level_atmosphere()

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

# ── Visual Atmosphere ────────────────────────────────────────────────────────

func _build_level_atmosphere() -> void:
	_ambient_layer = Node2D.new()
	_ambient_layer.name = "AmbientGardenDetails"
	_ambient_layer.z_index = 80
	add_child(_ambient_layer)
	move_child(_ambient_layer, 2)

	for i in range(4):
		var ray := Line2D.new()
		ray.name = "SunRay%d" % i
		ray.z_index = -70
		ray.width = 26.0 + i * 7.0
		ray.default_color = Color(1.0, 0.92, 0.48, 0.08 - i * 0.01)
		_ambient_layer.add_child(ray)
		_sun_rays.append(ray)

	_ambient_items.clear()
	for i in range(28):
		var item := Label.new()
		item.name = "AmbientIcon%d" % i
		item.text = AMBIENT_ICONS[i % AMBIENT_ICONS.size()]
		item.z_index = 90
		item.add_theme_font_size_override("font_size", 13 + (i % 4) * 3)
		item.add_theme_color_override("font_color", Color(1.0, 0.95, 0.54, 0.44))
		item.add_theme_color_override("font_outline_color", Color(0.04, 0.14, 0.03, 0.38))
		item.add_theme_constant_override("outline_size", 2)
		_ambient_layer.add_child(item)
		_ambient_items.append({"node": item, "phase": randf() * TAU, "speed": randf_range(0.35, 0.85), "drift": randf_range(8.0, 22.0)})

	_atmosphere_layer = CanvasLayer.new()
	_atmosphere_layer.name = "AtmosphereOverlay"
	_atmosphere_layer.layer = 8
	add_child(_atmosphere_layer)

	var sunlight := ColorRect.new()
	sunlight.name = "SunlightWash"
	sunlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sunlight.color = Color(1.0, 0.82, 0.34, 0.07)
	_atmosphere_layer.add_child(sunlight)

	var vignette := ColorRect.new()
	vignette.name = "SoftVignette"
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.color = Color(0.0, 0.08, 0.02, 0.10)
	_atmosphere_layer.add_child(vignette)

	_layout_level_atmosphere()

func _layout_level_atmosphere() -> void:
	var viewport_size := get_viewport_rect().size
	for i in range(_sun_rays.size()):
		var ray := _sun_rays[i]
		if ray == null:
			continue
		var start := Vector2(-80.0 + i * 90.0, -40.0)
		var end := Vector2(viewport_size.x * (0.42 + i * 0.12), viewport_size.y + 90.0)
		ray.points = PackedVector2Array([start, end])
	for i in range(_ambient_items.size()):
		var item := _ambient_items[i]["node"] as Label
		if item == null:
			continue
		var column := float(i % 7) / 6.0
		var row := float(i / 7) / 4.0
		var base := Vector2(70.0 + column * (viewport_size.x - 140.0), 118.0 + row * (viewport_size.y - 180.0))
		_ambient_items[i]["base"] = base
		item.position = base
	if _atmosphere_layer != null:
		var sunlight := _atmosphere_layer.get_node_or_null("SunlightWash") as ColorRect
		if sunlight != null:
			sunlight.position = Vector2.ZERO
			sunlight.size = Vector2(viewport_size.x, viewport_size.y * 0.48)
		var vignette := _atmosphere_layer.get_node_or_null("SoftVignette") as ColorRect
		if vignette != null:
			vignette.position = Vector2(0.0, viewport_size.y * 0.70)
			vignette.size = Vector2(viewport_size.x, viewport_size.y * 0.30)

func _update_level_atmosphere(delta: float) -> void:
	for i in range(_sun_rays.size()):
		var ray := _sun_rays[i]
		if ray != null:
			ray.default_color.a = 0.045 + (sin(Time.get_ticks_msec() * 0.0007 + i) + 1.0) * 0.018
	for data in _ambient_items:
		var item := data["node"] as Label
		if item == null:
			continue
		data["phase"] = float(data["phase"]) + delta * float(data["speed"])
		var phase := float(data["phase"])
		var base := data.get("base", item.position) as Vector2
		var drift := float(data["drift"])
		item.position = base + Vector2(cos(phase * 0.65) * drift, sin(phase) * drift * 0.45)
		item.rotation = sin(phase * 0.8) * 0.16
		item.modulate.a = 0.26 + (sin(phase * 1.4) + 1.0) * 0.15

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if not transitioning:
		GameManager.tick_timer(delta)
	_update_level_atmosphere(delta)
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
	var used: Array = []

	# Keep centre clear for player start
	used.append(Vector2(512, 380))

	for _i in range(config["carrot_count"]):
		_spawn(CARROT_SCENE, used, false)

	for _i in range(config["golden_carrot_count"]):
		_spawn(CARROT_SCENE, used, true)

	for _i in range(config["hole_count"]):
		_spawn_hazard(HOLE_SCENE, used, true)

	for _i in range(config["thorn_count"]):
		_spawn_hazard(THORN_SCENE, used, false)

	for _i in range(config["fox_count"]):
		_spawn_fox(used)

func _random_pos(used: Array, min_dist: float = 55.0) -> Vector2:
	var pos := Vector2.ZERO
	for _attempt in range(80):
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
	obj.global_position = _random_pos(used)
	# Property setter handles the colour update
	if "is_golden" in obj:
		obj.is_golden = golden

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
	obj.global_position = _random_pos(used, 60.0)
	# Property setter handles the colour update
	if "is_hole" in obj:
		obj.is_hole = is_hole

func _spawn_fox(used: Array) -> void:
	if not ResourceLoader.exists(FOX_SCENE):
		push_warning("GameLevel: Fox scene not found")
		return
	var packed := load(FOX_SCENE) as PackedScene
	if packed == null:
		return
	var fox := packed.instantiate()
	add_child(fox)
	fox.scale = Vector2(1.08, 1.08)
	fox.global_position = _random_pos(used, 100.0)
	if "patrol_distance" in fox:
		fox.patrol_distance = randf_range(100.0, 190.0)
	if "move_right_first" in fox:
		fox.move_right_first = (randi() % 2 == 0)

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
