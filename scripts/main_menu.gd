extends Control

# =============================================
# MainMenu Scene Controller
# =============================================

@onready var start_btn:   Button = $CenterContainer/VBoxContainer/StartButton
@onready var instr_btn:   Button = $CenterContainer/VBoxContainer/InstructionsButton
@onready var map_btn:     Button = $CenterContainer/VBoxContainer/LevelMapButton
@onready var quit_btn:    Button = $CenterContainer/VBoxContainer/QuitButton
@onready var settings_btn: Button = $SettingsButton
@onready var title_label: Label  = $TitleLabel

var _bounce_t: float = 0.0

func _ready() -> void:
	AudioManager.play_menu_music()
	start_btn.pressed.connect(_on_start)
	instr_btn.pressed.connect(_on_instructions)
	map_btn.pressed.connect(_on_level_map)
	quit_btn.pressed.connect(_on_quit)
	settings_btn.pressed.connect(_on_settings)

func _process(delta: float) -> void:
	_bounce_t += delta
	if title_label and not bool(SettingsManager.get_setting("reduce_motion")):
		title_label.position.y = 28.0 + sin(_bounce_t * 1.6) * 6.0

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
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_quit() -> void:
	AudioManager.play_button_click()
	get_tree().quit()
