extends Control

# يتحكم في شاشة اختيار الارنب وحفظ الشخصية المختارة قبل بدء اللعب

# مراجع جاهزة لعقد المشهد حتى يتم تعديل النصوص والازرار والرسوم بسرعة
@onready var white_btn:   Button    = $CenterContainer/VBoxContainer/WhiteButton
@onready var alt_white_btn: Button   = $CenterContainer/VBoxContainer/WhiteAltButton
@onready var dune_btn: Button        = $CenterContainer/VBoxContainer/DuneButton
@onready var snow_btn: Button        = $CenterContainer/VBoxContainer/SnowButton
@onready var confirm_btn: Button    = $CenterContainer/VBoxContainer/ConfirmButton
@onready var back_btn:    Button    = $BackButton
@onready var title_label: Label     = $TitleLabel
@onready var preview:     ColorRect = $PreviewRect
@onready var ear_l:       ColorRect = $PreviewEarL
@onready var ear_r:       ColorRect = $PreviewEarR
@onready var name_label:  Label     = $CharNameLabel

# متغيرات تحفظ حالة هذا السكربت اثناء اللعب
var _selected: String = "white_bunny"

# يبدأ تجهيز هذا المشهد عند دخوله الى شجرة اللعبة
func _ready() -> void:
	_selected = GameManager.selected_character
	_apply_language()
	SettingsManager.apply_wooden_buttons(self)
	white_btn.pressed.connect(func(): _pick("white_bunny"))
	alt_white_btn.pressed.connect(func(): _pick("brown_bunny"))
	dune_btn.pressed.connect(func(): _pick("dune_hare"))
	snow_btn.pressed.connect(func(): _pick("snow_scout"))
	confirm_btn.pressed.connect(_on_confirm)
	back_btn.pressed.connect(_on_back)
	_update_preview()

# يطبق النصوص المناسبة للغة الحالية على عناصر الواجهة
func _apply_language() -> void:
	title_label.text = SettingsManager.text("choose_bunny")
	white_btn.text = SettingsManager.text("white_bunny_button")
	alt_white_btn.text = SettingsManager.text("brown_bunny_button")
	dune_btn.text = SettingsManager.text("select_dune_bunny_button")
	snow_btn.text = SettingsManager.text("select_snow_bunny_button")
	confirm_btn.text = SettingsManager.text("confirm_play")
	back_btn.text = "← " + SettingsManager.text("back")

# يغير الشخصية المختارة ويحدث المعاينة
func _pick(char_name: String) -> void:
	AudioManager.play_button_click()
	_selected = char_name
	_update_preview()

# يحدث معاينة الشكل او الاعدادات حسب الاختيار الحالي
func _update_preview() -> void:
	var skin := GameManager.get_skin_data(_selected)
	var col: Color = skin["body_color"]
	if preview:   preview.color = col
	if ear_l:     ear_l.color   = col
	if ear_r:     ear_r.color   = col
	if name_label:
		name_label.text = SettingsManager.text(str(skin["name_key"]))

# يؤكد الاختيار وينتقل الى اللعب
func _on_confirm() -> void:
	AudioManager.play_button_click()
	GameManager.selected_character = _selected
	GameManager.save_progress()
	GameManager.start_level(1)
	get_tree().change_scene_to_file("res://scenes/GameLevel.tscn")

# يرجع الى الشاشة السابقة
func _on_back() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
