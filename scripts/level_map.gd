extends Control

# =============================================
# Level Map — Scenic trail level selection + locks
# =============================================

@onready var btn1: Button = $Level1Button
@onready var btn2: Button = $Level2Button
@onready var btn3: Button = $Level3Button
@onready var lock2: Label = $Lock2Label
@onready var lock3: Label = $Lock3Label
@onready var back_btn: Button = $BackButton

func _ready() -> void:
	btn1.pressed.connect(func(): _go(1))
	btn2.pressed.connect(func(): _go(2))
	btn3.pressed.connect(func(): _go(3))
	back_btn.pressed.connect(_on_back)
	_refresh_locks()

func _refresh_locks() -> void:
	var u: int = GameManager.levels_unlocked

	btn2.disabled = u < 2
	lock2.visible = u < 2

	btn3.disabled = u < 3
	lock3.visible = u < 3

func _go(level: int) -> void:
	AudioManager.play_button_click()
	GameManager.start_level(level)
	get_tree().change_scene_to_file("res://scenes/GameLevel.tscn")

func _on_back() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
