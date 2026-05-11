extends Control

# =============================================
# Instructions Screen
# =============================================

@onready var back_btn: Button = $BackButton

func _ready() -> void:
	back_btn.pressed.connect(_on_back)

func _on_back() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
