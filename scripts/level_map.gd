extends Control

# =============================================
# Level Map — Scenic trail level selection + locks
# =============================================

@onready var title_label: Label = $TitleLabel
@onready var title_shadow: Label = $TitleTextShadow
@onready var btn1: Button = $Level1Button
@onready var btn2: Button = $Level2Button
@onready var btn3: Button = $Level3Button
@onready var info1: Label = $Level1Info
@onready var info2: Label = $Level2Info
@onready var info3: Label = $Level3Info
@onready var lock2: Label = $Lock2Label
@onready var lock3: Label = $Lock3Label
@onready var legend_label: Label = $LegendLabel
@onready var back_btn: Button = $BackButton

func _ready() -> void:
	_apply_language()
	SettingsManager.apply_wooden_buttons(self)
	btn1.pressed.connect(func(): _go(1))
	btn2.pressed.connect(func(): _go(2))
	btn3.pressed.connect(func(): _go(3))
	back_btn.pressed.connect(_on_back)
	_refresh_locks()

func _apply_language() -> void:
	title_label.text = SettingsManager.text("map_title")
	if title_shadow != null:
		title_shadow.text = title_label.text
	btn1.text = SettingsManager.text("level1_name")
	btn2.text = SettingsManager.text("level2_name")
	btn3.text = SettingsManager.text("level3_name")
	lock2.text = SettingsManager.text("level1_lock")
	lock3.text = SettingsManager.text("level2_lock")
	legend_label.text = SettingsManager.text("map_legend")
	back_btn.text = "← " + SettingsManager.text("back")
	_update_level_info()

func _update_level_info() -> void:
	var labels := [info1, info2, info3]
	for index in range(labels.size()):
		var config: Dictionary = GameManager.get_level_config(index + 1)
		var hearts := ""
		for _i in range(int(config["lives"])):
			hearts += "❤"
		labels[index].text = "⏱ %d%s | %s | 🎯 %d" % [int(config["time_limit"]), SettingsManager.text("seconds_suffix"), hearts, int(config["required_score"])]

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
