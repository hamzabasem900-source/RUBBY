extends CanvasLayer

# =============================================
# HUD — Score / Time / Lives / Level
# =============================================

@onready var score_label:  Label          = $MarginContainer/TopBar/ScoreLabel
@onready var time_label:   Label          = $MarginContainer/TopBar/TimeLabel
@onready var level_label:  Label          = $MarginContainer/TopBar/LevelLabel
@onready var tip_label:    Label          = $MarginContainer/TopBar/TipLabel
@onready var hearts_box:   HBoxContainer  = $MarginContainer/TopBar/HeartsContainer

var heart_labels: Array = []
var max_lives: int = 3
var _last_heart_tween: Tween

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.time_changed.connect(_on_time_changed)

	# Build the exact number of hearts for this level.
	var config: Dictionary = GameManager.get_level_config(GameManager.current_level)
	max_lives = int(config["lives"])
	_rebuild_hearts(GameManager.lives)

	# Initial refresh
	_on_score_changed(GameManager.score)
	_on_lives_changed(GameManager.lives)
	_on_time_changed(GameManager.time_remaining)
	level_label.text = "🌿 " + SettingsManager.text("level") + " " + str(GameManager.current_level)
	tip_label.text = SettingsManager.text("dash_tip")

func _on_score_changed(val: int) -> void:
	if score_label:
		var config: Dictionary = GameManager.get_level_config(GameManager.current_level)
		score_label.text = "🥕 %d / %d" % [val, config["required_score"]]

func _on_lives_changed(val: int) -> void:
	_rebuild_hearts(val)

func _rebuild_hearts(val: int) -> void:
	if not hearts_box:
		return
	_stop_last_heart_warning()
	for child in hearts_box.get_children():
		child.free()
	heart_labels.clear()
	var visible_hearts: int = min(max(val, 0), max_lives)
	for i in range(visible_hearts):
		var lbl := Label.new()
		lbl.text = "❤"
		lbl.add_theme_font_size_override("font_size", 34)
		lbl.add_theme_color_override("font_color", Color(1, 0.12, 0.18))
		hearts_box.add_child(lbl)
		heart_labels.append(lbl)
	if visible_hearts == 1:
		_start_last_heart_warning(heart_labels[0])

func _start_last_heart_warning(heart_label: Label) -> void:
	heart_label.pivot_offset = heart_label.size * 0.5
	_last_heart_tween = create_tween()
	_last_heart_tween.set_loops()
	_last_heart_tween.tween_property(heart_label, "modulate", Color(1.0, 1.0, 1.0, 0.25), 0.22)
	_last_heart_tween.parallel().tween_property(heart_label, "scale", Vector2(1.25, 1.25), 0.22)
	_last_heart_tween.tween_property(heart_label, "modulate", Color(1.0, 0.12, 0.18, 1.0), 0.22)
	_last_heart_tween.parallel().tween_property(heart_label, "scale", Vector2.ONE, 0.22)

func _stop_last_heart_warning() -> void:
	if _last_heart_tween != null:
		_last_heart_tween.kill()
		_last_heart_tween = null
	for heart in heart_labels:
		if is_instance_valid(heart):
			heart.modulate = Color.WHITE
			heart.scale = Vector2.ONE

func _on_time_changed(val: float) -> void:
	if not time_label:
		return
	var secs: int = int(ceil(val))
	time_label.text = "⏱ %d" % secs
	if val <= 10.0:
		time_label.add_theme_color_override("font_color", Color(1, 0.15, 0.15))
	elif val <= 20.0:
		time_label.add_theme_color_override("font_color", Color(1, 0.7, 0.0))
	else:
		time_label.add_theme_color_override("font_color", Color(1, 1, 1))
