extends Control

# =============================================
# Win Screen
# =============================================

@onready var msg_label:    Label  = $CenterContainer/VBoxContainer/MessageLabel
@onready var score_label:  Label  = $CenterContainer/VBoxContainer/ScoreLabel
@onready var next_btn:     Button = $CenterContainer/VBoxContainer/NextButton
@onready var replay_btn:   Button = $CenterContainer/VBoxContainer/ReplayButton
@onready var menu_btn:     Button = $CenterContainer/VBoxContainer/MenuButton

const MESSAGES: Array = [
	"Amazing job! 🌟",
	"You're a carrot champion! 🥕",
	"Brilliant bunny! 🐰",
	"Wow, you're unstoppable! ⭐",
	"Super hop! Keep going! 🎉"
]

func _ready() -> void:
	next_btn.pressed.connect(_on_next)
	replay_btn.pressed.connect(_on_replay)
	menu_btn.pressed.connect(_on_menu)

	msg_label.text   = MESSAGES[randi() % MESSAGES.size()]
	score_label.text = "Final Score: " + str(GameManager.score) + " 🥕"

	if GameManager.current_level >= 3:
		next_btn.text     = "🎉 All Levels Complete!"
		next_btn.disabled = true

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
