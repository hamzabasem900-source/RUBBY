extends Control

# يعرض نتيجة المرحلة وعدد النجوم والازرار الخاصة بالمتابعة

# مراجع جاهزة لعقد المشهد حتى يتم تعديل النصوص والازرار والرسوم بسرعة
@onready var title_label: Label = $TitleLabel
@onready var score_label: Label  = $CenterContainer/VBoxContainer/ScoreLabel
@onready var time_label:  Label  = $CenterContainer/VBoxContainer/TimeLabel
@onready var stars_label: Label  = $CenterContainer/VBoxContainer/StarsLabel
@onready var retry_btn:   Button = $CenterContainer/VBoxContainer/RetryButton
@onready var map_btn:     Button = $CenterContainer/VBoxContainer/MapButton
@onready var menu_btn:    Button = $CenterContainer/VBoxContainer/MenuButton

# يبدأ تجهيز هذا المشهد عند دخوله الى شجرة اللعبة
func _ready() -> void:
	retry_btn.pressed.connect(_on_retry)
	map_btn.pressed.connect(_on_map)
	menu_btn.pressed.connect(_on_menu)
	_apply_language()
	_show_results()
	SettingsManager.apply_wooden_buttons(self)

# يطبق النصوص المناسبة للغة الحالية على عناصر الواجهة
func _apply_language() -> void:
	title_label.text = SettingsManager.text("result_title")
	retry_btn.text = SettingsManager.text("retry")
	map_btn.text = SettingsManager.text("level_map")
	menu_btn.text = SettingsManager.text("main_menu")

# يحسب ويعرض نتيجة المرحلة والنجوم
func _show_results() -> void:
	score_label.text = SettingsManager.format_text("your_score", {"score": GameManager.score})

	var limit: float = GameManager.get_level_config(GameManager.current_level)["time_limit"]
	var used: int    = int(limit - GameManager.time_remaining)
	time_label.text = SettingsManager.format_text("time_used", {"time": used})

	var stars: int     = GameManager.get_star_rating()
	var star_str: String = ""
	for i in range(3):
		star_str += "⭐" if i < stars else "☆"
	stars_label.text = star_str

# يعيد محاولة المرحلة من شاشة النتائج
func _on_retry() -> void:
	AudioManager.play_button_click()
	GameManager.start_level(GameManager.current_level)
	get_tree().change_scene_to_file("res://scenes/GameLevel.tscn")

# يرجع الى خريطة المراحل
func _on_map() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/LevelMap.tscn")

# يرجع الى القائمة الرئيسية
func _on_menu() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
