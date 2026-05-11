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

func _ready() -> void:
	AudioManager.play_menu_music()
	_apply_language()
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
