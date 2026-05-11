extends Control

# =============================================
# MainMenu Scene Controller
# =============================================

@onready var start_btn:   Button = $CenterContainer/VBoxContainer/StartButton
@onready var instr_btn:   Button = $CenterContainer/VBoxContainer/InstructionsButton
@onready var map_btn:     Button = $CenterContainer/VBoxContainer/LevelMapButton
@onready var quit_btn:    Button = $CenterContainer/VBoxContainer/QuitButton
@onready var settings_btn: Button = $SettingsButton
@onready var settings_hint: Label = $SettingsHint
@onready var title_label: Label  = $TitleLabel
@onready var subtitle_label: Label = $SubTitle

var _bounce_t: float = 0.0
var _opening_settings: bool = false
var _wallet_label: Label
var _bunny_preview: Label
var _skin_button: Button

func _ready() -> void:
	AudioManager.play_menu_music()
	_build_reward_panel()
	_apply_language()
	_update_reward_panel(GameManager.carrot_wallet)
	SettingsManager.apply_wooden_buttons(self)
	GameManager.carrot_wallet_changed.connect(_update_reward_panel)
	start_btn.pressed.connect(_on_start)
	instr_btn.pressed.connect(_on_instructions)
	map_btn.pressed.connect(_on_level_map)
	quit_btn.pressed.connect(_on_quit)
	settings_btn.pressed.connect(_on_settings)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if settings_btn.get_global_rect().has_point(mouse_event.position):
				open_settings()

func _process(delta: float) -> void:
	_bounce_t += delta
	if title_label:
		title_label.position.y = 28.0 + sin(_bounce_t * 1.6) * 6.0

func _apply_language() -> void:
	title_label.text = SettingsManager.text("app_title")
	subtitle_label.text = SettingsManager.text("main_subtitle")
	settings_hint.text = SettingsManager.text("settings")
	start_btn.text = SettingsManager.text("start_game")
	instr_btn.text = SettingsManager.text("instructions")
	map_btn.text = SettingsManager.text("level_map")
	quit_btn.text = SettingsManager.text("quit")
	if _skin_button != null:
		_skin_button.text = SettingsManager.text("change_bunny")

func _build_reward_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "RewardPanel"
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -220
	panel.offset_top = 330
	panel.offset_right = -34
	panel.offset_bottom = -32
	panel.add_theme_stylebox_override("panel", _reward_panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	_bunny_preview = Label.new()
	_bunny_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bunny_preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bunny_preview.custom_minimum_size = Vector2(142, 86)
	_bunny_preview.add_theme_font_size_override("font_size", 58)
	box.add_child(_bunny_preview)

	_wallet_label = Label.new()
	_wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wallet_label.add_theme_font_size_override("font_size", 24)
	_wallet_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.52, 1.0))
	box.add_child(_wallet_label)

	_skin_button = Button.new()
	_skin_button.custom_minimum_size = Vector2(148, 48)
	_skin_button.disabled = true
	box.add_child(_skin_button)

func _reward_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.16, 0.07, 0.54)
	style.border_color = Color(0.98, 0.80, 0.24, 0.82)
	style.set_border_width_all(3)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _update_reward_panel(total_carrots: int) -> void:
	if _wallet_label != null:
		_wallet_label.text = SettingsManager.format_text("carrot_wallet", {"count": total_carrots})
	if _bunny_preview != null:
		_bunny_preview.text = "🐰" if GameManager.selected_character == "white_bunny" else "🐇"

func _on_start() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")

func _on_instructions() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Instructions.tscn")

func _on_level_map() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/LevelMap.tscn")

func _on_settings() -> void:
	open_settings()

func open_settings() -> void:
	if _opening_settings:
		return
	_opening_settings = true
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_quit() -> void:
	AudioManager.play_button_click()
	get_tree().quit()
