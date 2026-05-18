extends CanvasLayer

# يعرض معلومات اللعب المهمة مثل النقاط والوقت والقلوب ورقم المرحلة

# مراجع جاهزة لعقد المشهد حتى يتم تعديل النصوص والازرار والرسوم بسرعة
@onready var score_label:  Label          = $MarginContainer/TopBar/ScoreLabel
@onready var time_label:   Label          = $MarginContainer/TopBar/TimeLabel
@onready var level_label:  Label          = $MarginContainer/TopBar/LevelLabel
@onready var tip_label:    Label          = $MarginContainer/TopBar/TipLabel
@onready var hearts_box:   HBoxContainer  = $MarginContainer/TopBar/HeartsContainer

# متغيرات تحفظ حالة هذا السكربت اثناء اللعب
var heart_labels: Array = []
var max_lives: int = 3
var _last_life_tween: Tween
var _dash_panel: PanelContainer
var _dash_label: Label
var _dash_bar: ProgressBar
var _player: Node

# يبدأ تجهيز هذا المشهد عند دخوله الى شجرة اللعبة
func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.time_changed.connect(_on_time_changed)

	var config: Dictionary = GameManager.get_level_config(GameManager.current_level)
	max_lives = int(config["lives"])
	_rebuild_hearts(GameManager.lives)

	_on_score_changed(GameManager.score)
	_on_lives_changed(GameManager.lives)
	_on_time_changed(GameManager.time_remaining)
	level_label.text = "🌿 " + SettingsManager.text("level") + " " + str(GameManager.current_level)
	tip_label.text = SettingsManager.text("dash_tip")
	_prepare_top_bar_spacing()
	_apply_text_scale()
	_build_dash_indicator()

# يحدث مؤشر تهدئة الاندفاع في كل اطار بدون ازدحام الشاشة
func _process(_delta: float) -> void:
	_update_dash_indicator()

# يجهز مسافات الشريط العلوي حتى تظهر القلوب كاملة
func _prepare_top_bar_spacing() -> void:
	var top_bar := hearts_box.get_parent() as HBoxContainer if hearts_box != null else null
	if top_bar != null:
		top_bar.add_theme_constant_override("separation", 12)
	if hearts_box != null:
		hearts_box.custom_minimum_size = Vector2(118, 44)
		hearts_box.size_flags_horizontal = Control.SIZE_SHRINK_END

# يطبق خيار تكبير وتصغير النص على عناصر HUD
func _apply_text_scale() -> void:
	for label in [score_label, time_label, level_label]:
		if label != null:
			label.add_theme_font_size_override("font_size", SettingsManager.scaled_font_size(34))
	if tip_label != null:
		tip_label.add_theme_font_size_override("font_size", SettingsManager.scaled_font_size(22))

# يبني مؤشر اندفاع صغير داخل الشريط العلوي
func _build_dash_indicator() -> void:
	if not bool(SettingsManager.get_setting("show_dash_hud")) or _dash_panel != null or hearts_box == null:
		return
	_dash_panel = PanelContainer.new()
	_dash_panel.custom_minimum_size = Vector2(146, 44)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.12, 0.10, 0.78)
	style.border_color = Color(0.30, 0.88, 1.0, 0.86)
	style.set_border_width_all(2)
	style.set_corner_radius_all(13)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	_dash_panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_dash_panel.add_child(box)
	_dash_label = Label.new()
	_dash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dash_label.add_theme_font_size_override("font_size", SettingsManager.scaled_font_size(14))
	_dash_label.add_theme_color_override("font_color", Color(0.86, 1.0, 1.0, 1.0))
	box.add_child(_dash_label)
	_dash_bar = ProgressBar.new()
	_dash_bar.min_value = 0
	_dash_bar.max_value = 100
	_dash_bar.show_percentage = false
	_dash_bar.custom_minimum_size = Vector2(124, 10)
	box.add_child(_dash_bar)
	add_child(_dash_panel)
	_dash_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_dash_panel.offset_left = -176.0
	_dash_panel.offset_top = 154.0
	_dash_panel.offset_right = -26.0
	_dash_panel.offset_bottom = 200.0

# يحدث نص ولون شريط الاندفاع
func _update_dash_indicator() -> void:
	if _dash_panel == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null or not _player.has_method("get_dash_status"):
		return
	var status: Dictionary = _player.get_dash_status()
	var ready := bool(status.get("ready", false))
	var progress := float(status.get("progress", 0.0))
	_dash_bar.value = progress * 100.0
	if ready:
		_dash_label.text = "💨 " + SettingsManager.text("dash_ready")
		_dash_label.add_theme_color_override("font_color", Color(0.68, 1.0, 0.74, 1.0))
	else:
		var left := float(status.get("cooldown_left", 0.0))
		_dash_label.text = SettingsManager.format_text("dash_cooling", {"time": snapped(left, 0.1)})
		_dash_label.add_theme_color_override("font_color", Color(0.72, 0.94, 1.0, 1.0))

# يشرح هذا الجزء وظيفة مساعدة داخل السكربت
func _on_score_changed(val: int) -> void:
	if score_label:
		var config: Dictionary = GameManager.get_level_config(GameManager.current_level)
		score_label.text = "🥕 %d / %d" % [val, config["required_score"]]

# يشرح هذا الجزء وظيفة مساعدة داخل السكربت
func _on_lives_changed(val: int) -> void:
	_rebuild_hearts(val)

# يشرح هذا الجزء وظيفة مساعدة داخل السكربت
func _rebuild_hearts(val: int) -> void:
	if not hearts_box:
		return
	_stop_last_life_blink()
	for child in hearts_box.get_children():
		child.free()
	heart_labels.clear()
	var visible_hearts: int = min(max(val, 0), max_lives)
	for i in range(visible_hearts):
		var lbl := Label.new()
		lbl.text = "❤"
		lbl.add_theme_font_size_override("font_size", SettingsManager.scaled_font_size(34))
		lbl.add_theme_color_override("font_color", Color(1, 0.12, 0.18))
		hearts_box.add_child(lbl)
		heart_labels.append(lbl)
	if visible_hearts == 1:
		_start_last_life_blink(heart_labels[0])

# يشرح هذا الجزء وظيفة مساعدة داخل السكربت
func _start_last_life_blink(heart: Label) -> void:
	if not heart:
		return
	heart.pivot_offset = Vector2(heart.size.x * 0.5, heart.size.y * 0.5)
	heart.modulate = Color(1, 1, 1, 1)
	heart.scale = Vector2.ONE
	_last_life_tween = create_tween()
	_last_life_tween.set_loops()
	_last_life_tween.set_trans(Tween.TRANS_SINE)
	_last_life_tween.set_ease(Tween.EASE_IN_OUT)
	_last_life_tween.tween_property(heart, "modulate:a", 0.28, 0.22)
	_last_life_tween.parallel().tween_property(heart, "scale", Vector2(1.25, 1.25), 0.22)
	_last_life_tween.tween_property(heart, "modulate:a", 1.0, 0.22)
	_last_life_tween.parallel().tween_property(heart, "scale", Vector2.ONE, 0.22)

# يشرح هذا الجزء وظيفة مساعدة داخل السكربت
func _stop_last_life_blink() -> void:
	if _last_life_tween and _last_life_tween.is_valid():
		_last_life_tween.kill()
	_last_life_tween = null
	for heart in heart_labels:
		if heart:
			heart.modulate = Color(1, 1, 1, 1)
			heart.scale = Vector2.ONE

# يشرح هذا الجزء وظيفة مساعدة داخل السكربت
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
