extends Control

# =============================================
# Win Screen
# =============================================

@onready var banner_label: Label = $WinBanner
@onready var msg_label:    Label  = $CenterContainer/VBoxContainer/MessageLabel
@onready var score_label:  Label  = $CenterContainer/VBoxContainer/ScoreLabel
@onready var next_btn:     Button = $CenterContainer/VBoxContainer/NextButton
@onready var replay_btn:   Button = $CenterContainer/VBoxContainer/ReplayButton
@onready var menu_btn:     Button = $CenterContainer/VBoxContainer/MenuButton

const MESSAGE_KEYS: Array[String] = [
	"win_message_1",
	"win_message_2",
	"win_message_3",
	"win_message_4",
	"win_message_5"
]

func _ready() -> void:
	next_btn.pressed.connect(_on_next)
	replay_btn.pressed.connect(_on_replay)
	menu_btn.pressed.connect(_on_menu)
	_apply_language()
	SettingsManager.apply_wooden_buttons(self)

	if GameManager.current_level >= 3:
		next_btn.text     = SettingsManager.text("all_levels_complete")
		next_btn.disabled = true

func _apply_language() -> void:
	banner_label.text = SettingsManager.text("win_banner")
	msg_label.text = SettingsManager.text(MESSAGE_KEYS[randi() % MESSAGE_KEYS.size()])
	score_label.text = SettingsManager.format_text("final_score", {"score": GameManager.score})
	next_btn.text = SettingsManager.text("next_level")
	replay_btn.text = SettingsManager.text("play_again")
	menu_btn.text = SettingsManager.text("main_menu")

func _on_next() -> void:
	AudioManager.play_button_click()
	var nxt: int = GameManager.current_level + 1
	if nxt <= 3:
		GameManager.start_level(nxt)
		get_tree().change_scene_to_file("res://scenes/GameLevel.tscn")

func _on_replay() -> void:
	AudioManager.play_button_click()
	GameManager.start_level(GameManager.current_level)
	get_tree().change_scene_to_file("res://scenes/GameLevel.tscn")

func _on_menu() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
