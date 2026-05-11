extends Control

# =============================================
# Game Over Screen
# =============================================

@onready var msg_label:   Label  = $CenterContainer/VBoxContainer/MessageLabel
@onready var score_label: Label  = $CenterContainer/VBoxContainer/ScoreLabel
@onready var retry_btn:   Button = $CenterContainer/VBoxContainer/TryAgainButton
@onready var menu_btn:    Button = $CenterContainer/VBoxContainer/MenuButton

const MESSAGES: Array = [
	"Oops! Don't give up, little bunny! 🐰",
	"So close! Try again! 💪",
	"The carrots are waiting for you! 🥕",
	"You can do it! One more hop! 🌟"
]

func _ready() -> void:
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_menu)

	msg_label.text   = MESSAGES[randi() % MESSAGES.size()]
	score_label.text = "You got: " + str(GameManager.score) + " points"

func _on_retry() -> void:
	AudioManager.play_button_click()
	GameManager.start_level(GameManager.current_level)
	get_tree().change_scene_to_file("res://scenes/GameLevel.tscn")

func _on_menu() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
