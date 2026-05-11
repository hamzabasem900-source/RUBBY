extends Control

# =============================================
# MainMenu Scene Controller
# Settings are built inside this existing scene/script only.
# No separate settings scene or manager is required.
# =============================================

const SETTINGS_PATH: String = "user://settings.cfg"
const SETTINGS_SECTION: String = "game"
const RESOLUTIONS: Array[String] = ["1024 x 720", "1280 x 720", "1600 x 900", "1920 x 1080"]
const DIFFICULTIES: Array[String] = ["Easy", "Normal", "Hard"]

@onready var start_btn:   Button = $CenterContainer/VBoxContainer/StartButton
@onready var instr_btn:   Button = $CenterContainer/VBoxContainer/InstructionsButton
@onready var map_btn:     Button = $CenterContainer/VBoxContainer/LevelMapButton
@onready var quit_btn:    Button = $CenterContainer/VBoxContainer/QuitButton
@onready var settings_btn: Button = $SettingsButton
@onready var title_label: Label  = $TitleLabel

var _bounce_t: float = 0.0
var _settings_overlay: Control
var _fps_label: Label
var _settings: Dictionary = {
	"fullscreen": false,
	"resolution": "1024 x 720",
	"show_fps": false,
	"reduce_motion": false,
	"master_volume": 0.85,
	"music_volume": 0.70,
	"sfx_volume": 0.85,
	"mute_audio": false,
	"difficulty": "Normal"
}

func _ready() -> void:
	_load_settings()
	_apply_settings()
	AudioManager.play_menu_music()
	start_btn.pressed.connect(_on_start)
	instr_btn.pressed.connect(_on_instructions)
	map_btn.pressed.connect(_on_level_map)
	quit_btn.pressed.connect(_on_quit)
	settings_btn.pressed.connect(_show_settings)
	_build_settings_overlay()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _settings_overlay != null and _settings_overlay.visible:
		_hide_settings()
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if settings_btn.get_global_rect().has_point(mouse_event.position):
				_show_settings()

func _process(delta: float) -> void:
	_bounce_t += delta
	if title_label and not bool(_settings["reduce_motion"]):
		title_label.position.y = 28.0 + sin(_bounce_t * 1.6) * 6.0
	_update_fps_label()

func _on_start() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")

func _on_instructions() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Instructions.tscn")

func _on_level_map() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/LevelMap.tscn")

func _on_quit() -> void:
	AudioManager.play_button_click()
	get_tree().quit()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for key in _settings.keys():
		_settings[key] = config.get_value(SETTINGS_SECTION, key, _settings[key])

func _save_settings() -> void:
	var config := ConfigFile.new()
	for key in _settings.keys():
		config.set_value(SETTINGS_SECTION, key, _settings[key])
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("MainMenu: could not save settings.cfg")

func _set_setting(key: String, value: Variant) -> void:
	_settings[key] = value
	_save_settings()
	_apply_settings()

func _apply_settings() -> void:
	_apply_display_settings()
	_apply_audio_settings()
	_apply_fps_label()

func _apply_display_settings() -> void:
	var root_window := get_tree().root
	root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root_window.content_scale_size = Vector2i(1024, 720)

	if bool(_settings["fullscreen"]):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return

	var size := _resolution_to_vector(str(_settings["resolution"]))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(size)
	var screen_size := DisplayServer.screen_get_size()
	DisplayServer.window_set_position((screen_size - size) / 2)

func _apply_audio_settings() -> void:
	_set_bus_volume("Master", float(_settings["master_volume"]), bool(_settings["mute_audio"]))
	_set_bus_volume("Music", float(_settings["music_volume"]), bool(_settings["mute_audio"]))
	_set_bus_volume("SFX", float(_settings["sfx_volume"]), bool(_settings["mute_audio"]))

func _set_bus_volume(bus_name: String, linear_value: float, muted: bool) -> void:
	_ensure_audio_bus(bus_name)
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	AudioServer.set_bus_mute(bus_idx, muted)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clamp(linear_value, 0.0, 1.0)))

func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(idx, bus_name)

func _apply_fps_label() -> void:
	if not bool(_settings["show_fps"]):
		if _fps_label != null:
			_fps_label.queue_free()
			_fps_label = null
		return
	if _fps_label != null:
		return
	_fps_label = Label.new()
	_fps_label.name = "FpsOverlay"
	_fps_label.z_index = 200
	_fps_label.position = Vector2(14, 12)
	_fps_label.add_theme_font_size_override("font_size", 18)
	_fps_label.add_theme_color_override("font_color", Color(1, 1, 0.55, 1))
	add_child(_fps_label)

func _update_fps_label() -> void:
	if _fps_label != null:
		_fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

func _resolution_to_vector(resolution: String) -> Vector2i:
	match resolution:
		"1280 x 720":
			return Vector2i(1280, 720)
		"1600 x 900":
			return Vector2i(1600, 900)
		"1920 x 1080":
			return Vector2i(1920, 1080)
		_:
			return Vector2i(1024, 720)

func _build_settings_overlay() -> void:
	_settings_overlay = ColorRect.new()
	_settings_overlay.name = "SettingsOverlay"
	_settings_overlay.visible = false
	_settings_overlay.z_index = 150
	_settings_overlay.color = Color(0, 0, 0, 0.62)
	_settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_settings_overlay)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 520)
	panel.size = Vector2(760, 520)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-380, -260)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.22, 0.10, 0.98)
	style.border_color = Color(0.62, 0.95, 0.45, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	_settings_overlay.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)

	var title := Label.new()
	title.text = "⚙ الإعدادات"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(52, 44)
	close_btn.pressed.connect(_hide_settings)
	header.add_child(close_btn)

	root.add_child(_section_label("العرض"))
	root.add_child(_check_row("ملء الشاشة", "fullscreen"))
	root.add_child(_option_row("الدقة", "resolution", RESOLUTIONS))
	root.add_child(_check_row("إظهار FPS", "show_fps"))
	root.add_child(_check_row("تقليل الحركة", "reduce_motion"))

	root.add_child(_section_label("الصوت"))
	root.add_child(_slider_row("الصوت الرئيسي", "master_volume"))
	root.add_child(_slider_row("الموسيقى", "music_volume"))
	root.add_child(_slider_row("المؤثرات", "sfx_volume"))
	root.add_child(_check_row("كتم كل الأصوات", "mute_audio"))

	root.add_child(_section_label("اللعب"))
	root.add_child(_option_row("الصعوبة", "difficulty", DIFFICULTIES))

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)

	var reset_btn := Button.new()
	reset_btn.text = "استعادة الافتراضي"
	reset_btn.custom_minimum_size = Vector2(220, 48)
	reset_btn.pressed.connect(_reset_settings)
	footer.add_child(reset_btn)

	var back_btn := Button.new()
	back_btn.text = "إغلاق"
	back_btn.custom_minimum_size = Vector2(220, 48)
	back_btn.pressed.connect(_hide_settings)
	footer.add_child(back_btn)

func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1, 1, 0.68, 1))
	return label

func _row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(210, 30)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.94, 0.98, 0.94, 1))
	row.add_child(label)
	return row

func _check_row(label_text: String, setting_key: String) -> HBoxContainer:
	var row := _row(label_text)
	var toggle := CheckButton.new()
	toggle.button_pressed = bool(_settings[setting_key])
	toggle.toggled.connect(func(pressed: bool) -> void:
		_set_setting(setting_key, pressed)
	)
	row.add_child(toggle)
	return row

func _slider_row(label_text: String, setting_key: String) -> HBoxContainer:
	var row := _row(label_text)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.custom_minimum_size = Vector2(220, 28)
	slider.value = round(float(_settings[setting_key]) * 100.0)
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(58, 28)
	value_label.text = str(int(slider.value)) + "%"
	value_label.add_theme_color_override("font_color", Color(1, 1, 0.72, 1))
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = str(int(value)) + "%"
		_set_setting(setting_key, value / 100.0)
	)
	row.add_child(value_label)
	return row

func _option_row(label_text: String, setting_key: String, options: Array[String]) -> HBoxContainer:
	var row := _row(label_text)
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(220, 34)
	for item in options:
		option.add_item(item)
	var selected_index := options.find(str(_settings[setting_key]))
	option.select(max(0, selected_index))
	option.item_selected.connect(func(index: int) -> void:
		_set_setting(setting_key, options[index])
	)
	row.add_child(option)
	return row

func _show_settings() -> void:
	if _settings_overlay.visible:
		return
	AudioManager.play_button_click()
	_settings_overlay.visible = true

func _hide_settings() -> void:
	AudioManager.play_button_click()
	_settings_overlay.visible = false

func _reset_settings() -> void:
	_settings = {
		"fullscreen": false,
		"resolution": "1024 x 720",
		"show_fps": false,
		"reduce_motion": false,
		"master_volume": 0.85,
		"music_volume": 0.70,
		"sfx_volume": 0.85,
		"mute_audio": false,
		"difficulty": "Normal"
	}
	_save_settings()
	_apply_settings()
	get_tree().reload_current_scene()
