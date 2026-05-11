extends CanvasLayer

# =============================================
# HUD — Score / Time / Lives / Level
# =============================================

@onready var score_label:  Label          = $MarginContainer/TopBar/ScoreLabel
@onready var time_label:   Label          = $MarginContainer/TopBar/TimeLabel
@onready var level_label:  Label          = $MarginContainer/TopBar/LevelLabel
@onready var hearts_box:   HBoxContainer  = $MarginContainer/TopBar/HeartsContainer

var heart_labels: Array = []
const MAX_LIVES: int    = 3

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.time_changed.connect(_on_time_changed)

	# Build heart icons
	for i in range(MAX_LIVES):
		var lbl := Label.new()
		lbl.text = "❤"
		lbl.add_theme_font_size_override("font_size", 26)
		lbl.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		hearts_box.add_child(lbl)
		heart_labels.append(lbl)

	# Initial refresh
	_on_score_changed(GameManager.score)
	_on_lives_changed(GameManager.lives)
	_on_time_changed(GameManager.time_remaining)
	level_label.text = "Level " + str(GameManager.current_level)

func _on_score_changed(val: int) -> void:
	if score_label:
		var config: Dictionary = GameManager.get_level_config(GameManager.current_level)
		score_label.text = "Score: %d / %d" % [val, config["required_score"]]

func _on_lives_changed(val: int) -> void:
	for i in range(MAX_LIVES):
		if i < heart_labels.size():
			heart_labels[i].add_theme_color_override(
				"font_color",
				Color(1, 0.2, 0.2) if i < val else Color(0.35, 0.35, 0.35)
			)

func _on_time_changed(val: float) -> void:
	if not time_label:
		return
	var secs: int = int(ceil(val))
	time_label.text = "Time: %d" % secs
	if val <= 10.0:
		time_label.add_theme_color_override("font_color", Color(1, 0.15, 0.15))
	elif val <= 20.0:
		time_label.add_theme_color_override("font_color", Color(1, 0.7, 0.0))
	else:
		time_label.add_theme_color_override("font_color", Color(1, 1, 1))
