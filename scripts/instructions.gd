extends Control

# =============================================
# Instructions Screen
# =============================================

@onready var title_label: Label = $TitleLabel
@onready var instructions_text: RichTextLabel = $Panel/InstructionsText
@onready var back_btn: Button = $BackButton

func _ready() -> void:
	_apply_language()
	back_btn.pressed.connect(_on_back)

func _apply_language() -> void:
	title_label.text = SettingsManager.text("how_to_play")
	instructions_text.text = SettingsManager.text("instructions_body")
	back_btn.text = "← " + SettingsManager.text("back")

func _on_back() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
