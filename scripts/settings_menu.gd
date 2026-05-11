extends Control

# =============================================
# Settings Menu
# A polished settings dashboard with live-save controls.
# =============================================

var _labels: Array[Label] = []
var _value_labels: Dictionary = {}
var _language_options: OptionButton
var _difficulty_options: OptionButton
var _resolution_options: OptionButton
var _preview_label: Label
var _action_buttons: Array[Button] = []

func _ready() -> void:
	AudioManager.play_menu_music()
	_build_interface()
	SettingsManager.language_changed.connect(_refresh_language)

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color(0.10, 0.30, 0.13, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var top_grass := ColorRect.new()
	top_grass.color = Color(0.14, 0.42, 0.16, 1.0)
	top_grass.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_grass.custom_minimum_size = Vector2(0, 102)
	top_grass.offset_bottom = 102
	add_child(top_grass)

	var title := Label.new()
	title.name = "SettingsTitle"
	title.text = "⚙  " + SettingsManager.text("settings")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 22
	title.offset_bottom = 82
	add_child(title)
	_labels.append(title)

	var subtitle := Label.new()
	subtitle.name = "SettingsSubtitle"
	subtitle.text = SettingsManager.text("settings_subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(1, 1, 0.70, 1))
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_top = 82
	subtitle.offset_bottom = 112
	add_child(subtitle)
	_labels.append(subtitle)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 48)
	root.add_theme_constant_override("margin_right", 48)
	root.add_theme_constant_override("margin_top", 128)
	root.add_theme_constant_override("margin_bottom", 34)
	add_child(root)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 18)
	scroll.add_child(layout)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 16)
	layout.add_child(grid)

	grid.add_child(_create_card("audio", [
		_create_slider_row("master_volume", "master_volume"),
		_create_slider_row("music_volume", "music_volume"),
		_create_slider_row("sfx_volume", "sfx_volume"),
		_create_check_row("mute_audio", "mute_audio"),
		_create_option_row("language", "language", ["English", "العربية"])
	]))

	grid.add_child(_create_card("visuals", [
		_create_check_row("fullscreen", "fullscreen"),
		_create_option_row("resolution", "resolution", ["1280 x 720", "1600 x 900", "1920 x 1080", "1024 x 720"]),
		_create_check_row("show_fps", "show_fps"),
		_create_check_row("reduce_motion", "reduce_motion")
	]))

	grid.add_child(_create_card("gameplay", [
		_create_option_row("difficulty", "difficulty", ["Easy", "Normal", "Hard"])
	]))

	grid.add_child(_create_preview_card())

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	layout.add_child(actions)

	var reset_btn := _create_action_button("reset", Color(1.0, 0.72, 0.28, 1.0))
	reset_btn.pressed.connect(_on_reset_pressed)
	actions.add_child(reset_btn)

	var back_btn := _create_action_button("back", Color(0.66, 0.94, 0.72, 1.0))
	back_btn.pressed.connect(_on_back_pressed)
	actions.add_child(back_btn)

func _create_card(title_key: String, rows: Array) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(446, 220)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.22, 0.10, 0.92)
	style.border_color = Color(0.48, 0.86, 0.42, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	panel.add_child(box)

	var title := Label.new()
	title.name = title_key + "Title"
	title.text = SettingsManager.text(title_key)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	box.add_child(title)
	_labels.append(title)

	for row in rows:
		box.add_child(row)
	return panel

func _create_slider_row(label_key: String, setting_key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := _create_row_label(label_key)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = round(float(SettingsManager.get_setting(setting_key)) * 100.0)
	slider.value_changed.connect(func(value: float) -> void:
		SettingsManager.set_setting(setting_key, value / 100.0)
		_update_value_label(setting_key, str(int(value)) + "%")
		_update_preview()
	)
	row.add_child(slider)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(52, 28)
	value_label.text = str(int(slider.value)) + "%"
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Color(1, 1, 0.75, 1))
	row.add_child(value_label)
	_value_labels[setting_key] = value_label
	return row

func _create_check_row(label_key: String, setting_key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_create_row_label(label_key))

	var toggle := CheckButton.new()
	toggle.button_pressed = bool(SettingsManager.get_setting(setting_key))
	toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
	toggle.toggled.connect(func(pressed: bool) -> void:
		SettingsManager.set_setting(setting_key, pressed)
		_update_preview()
	)
	row.add_child(toggle)
	return row

func _create_option_row(label_key: String, setting_key: String, options: Array[String]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_create_row_label(label_key))

	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(170, 34)
	for item in options:
		option.add_item(item)
	var current := str(SettingsManager.get_setting(setting_key))
	var current_value = SettingsManager.get_setting(setting_key)
	var selected_index: int = int(max(0, options.find(current_value)))
	option.select(selected_index)
	option.item_selected.connect(func(index: int) -> void:
		SettingsManager.set_setting(setting_key, options[index])
		_update_preview()
	)
	row.add_child(option)
	if setting_key == "language":
		_language_options = option
	elif setting_key == "difficulty":
		_difficulty_options = option
	elif setting_key == "resolution":
		_resolution_options = option
	return row

func _create_row_label(label_key: String) -> Label:
	var label := Label.new()
	label.name = label_key + "Label"
	label.text = SettingsManager.text(label_key)
	label.custom_minimum_size = Vector2(190, 30)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.92, 0.98, 0.92, 1))
	_labels.append(label)
	return label

func _create_preview_card() -> PanelContainer:
	var panel := _create_card("preview", [])
	_preview_label = Label.new()
	_preview_label.add_theme_font_size_override("font_size", 22)
	_preview_label.add_theme_color_override("font_color", Color(1, 0.95, 0.72, 1))
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_label.custom_minimum_size = Vector2(390, 130)
	panel.get_child(0).add_child(_preview_label)
	_update_preview()
	return panel

func _create_action_button(text_key: String, font_color: Color) -> Button:
	var button := Button.new()
	button.name = text_key + "Button"
	button.text = SettingsManager.text(text_key)
	button.custom_minimum_size = Vector2(260, 58)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", font_color)
	_action_buttons.append(button)
	return button

func _update_value_label(key: String, text: String) -> void:
	if _value_labels.has(key):
		_value_labels[key].text = text

func _update_preview() -> void:
	if _preview_label == null:
		return
	_preview_label.text = "🥕 " + SettingsManager.text("language") + ": " + str(SettingsManager.get_setting("language")) + "\n" + \
		"🔊 " + SettingsManager.text("master_volume") + ": " + str(int(float(SettingsManager.get_setting("master_volume")) * 100.0)) + "%\n" + \
		"🎮 " + SettingsManager.text("difficulty") + ": " + str(SettingsManager.get_setting("difficulty")) + "\n" + \
		"🖥 " + SettingsManager.text("resolution") + ": " + str(SettingsManager.get_setting("resolution")) + " • " + SettingsManager.text("fullscreen") + ": " + ("ON" if bool(SettingsManager.get_setting("fullscreen")) else "OFF")

func _refresh_language(_language: String) -> void:
	for label in _labels:
		var key := label.name.replace("Label", "").replace("Title", "")
		if label.name == "SettingsTitle":
			label.text = "⚙  " + SettingsManager.text("settings")
		elif label.name == "SettingsSubtitle":
			label.text = SettingsManager.text("settings_subtitle")
		else:
			label.text = SettingsManager.text(key)
	for button in _action_buttons:
		button.text = SettingsManager.text(button.name.replace("Button", ""))
	_update_preview()

func _on_reset_pressed() -> void:
	AudioManager.play_button_click()
	SettingsManager.reset_to_defaults()
	get_tree().reload_current_scene()

func _on_back_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
