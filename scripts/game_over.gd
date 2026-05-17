extends Control

# يتحكم في شاشة الخسارة وازرار الاعادة والعودة للقائمة

# مراجع جاهزة لعقد المشهد حتى يتم تعديل النصوص والازرار والرسوم بسرعة
@onready var banner_label: Label = $GameOverBanner
@onready var msg_label:   Label  = $CenterContainer/VBoxContainer/MessageLabel
@onready var score_label: Label  = $CenterContainer/VBoxContainer/ScoreLabel
@onready var retry_btn:   Button = $CenterContainer/VBoxContainer/TryAgainButton
@onready var menu_btn:    Button = $CenterContainer/VBoxContainer/MenuButton

# قيم ثابتة يستخدمها هذا السكربت اثناء التشغيل
const MESSAGE_KEYS: Array[String] = [
	"game_over_message_1",
	"game_over_message_2",
	"game_over_message_3",
	"game_over_message_4"
]

# يبدأ تجهيز هذا المشهد عند دخوله الى شجرة اللعبة
func _ready() -> void:
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_menu)
	_apply_language()
	SettingsManager.apply_wooden_buttons(self)

# يطبق النصوص المناسبة للغة الحالية على عناصر الواجهة
func _apply_language() -> void:
	banner_label.text = SettingsManager.text("game_over_banner")
	msg_label.text = SettingsManager.text(MESSAGE_KEYS[randi() % MESSAGE_KEYS.size()])
	score_label.text = SettingsManager.format_text("game_over_score", {"score": GameManager.score})
	retry_btn.text = SettingsManager.text("try_again")
	menu_btn.text = SettingsManager.text("main_menu")

# يعيد محاولة المرحلة من شاشة النتائج
func _on_retry() -> void:
	AudioManager.stop_end_screen_sfx()
	AudioManager.play_button_click()
	GameManager.start_level(GameManager.current_level)
	get_tree().change_scene_to_file("res://scenes/GameLevel.tscn")

# يرجع الى القائمة الرئيسية
func _on_menu() -> void:
	AudioManager.stop_end_screen_sfx()
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
