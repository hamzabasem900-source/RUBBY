extends Control
@onready var white_btn:   Button    = $CenterContainer/VBoxContainer/WhiteButton
@onready var alt_white_btn: Button   = $CenterContainer/VBoxContainer/WhiteAltButton
@onready var confirm_btn: Button    = $CenterContainer/VBoxContainer/ConfirmButton
@onready var back_btn:    Button    = $BackButton
@onready var title_label: Label     = $TitleLabel
@onready var preview:     ColorRect = $PreviewRect
@onready var ear_l:       ColorRect = $PreviewEarL
@onready var ear_r:       ColorRect = $PreviewEarR
@onready var name_label:  Label     = $CharNameLabel

var _selected: String = "white_bunny"

func _ready() -> void:
	_selected = GameManager.selected_character
	_apply_language()
	SettingsManager.apply_wooden_buttons(self)
	white_btn.pressed.connect(func(): _pick("white_bunny"))
	alt_white_btn.pressed.connect(func(): _pick("brown_bunny"))
	confirm_btn.pressed.connect(_on_confirm)
	back_btn.pressed.connect(_on_back)
	_update_preview()

func _apply_language() -> void:
	title_label.text = SettingsManager.text("choose_bunny")
	white_btn.text = SettingsManager.text("white_bunny_button")
	alt_white_btn.text = SettingsManager.text("brown_bunny_button")
	confirm_btn.text = SettingsManager.text("confirm_play")
	back_btn.text = "← " + SettingsManager.text("back")

func _pick(char_name: String) -> void:
	AudioManager.play_button_click()
	_selected = char_name
	_update_preview()

func _update_preview() -> void:
	var skin := GameManager.get_skin_data(_selected)
	var col: Color = skin["body_color"]
	if preview:   preview.color = col
	if ear_l:     ear_l.color   = col
	if ear_r:     ear_r.color   = col
	if name_label:
		name_label.text = SettingsManager.text(str(skin["name_key"]))

func _on_confirm() -> void:
	AudioManager.play_button_click()
	GameManager.selected_character = _selected
	GameManager.save_progress()
	GameManager.start_level(1)
	get_tree().change_scene_to_file("res://scenes/GameLevel.tscn")

func _on_back() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
