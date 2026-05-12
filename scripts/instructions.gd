extends Control

# =============================================
# Instructions Screen
# Card-based, friendly guide for new players.
# =============================================

@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var cards_host: MarginContainer = $CardsHost
@onready var back_btn: Button = $BackButton

const CARD_DATA: Array[Dictionary] = [
	{
		"title": "instructions_controls_title",
		"body": "instructions_controls_body",
		"icon": "🎮",
		"accent": Color(0.32, 0.76, 0.95, 1.0)
	},
	{
		"title": "instructions_collect_title",
		"body": "instructions_collect_body",
		"icon": "🥕",
		"accent": Color(1.0, 0.62, 0.18, 1.0)
	},
	{
		"title": "instructions_hazards_title",
		"body": "instructions_hazards_body",
		"icon": "⚠",
		"accent": Color(0.95, 0.36, 0.28, 1.0)
	},
	{
		"title": "instructions_goal_title",
		"body": "instructions_goal_body",
		"icon": "🎯",
		"accent": Color(0.56, 0.88, 0.38, 1.0)
	},
	{
		"title": "instructions_lives_title",
		"body": "instructions_lives_body",
		"icon": "❤",
		"accent": Color(1.0, 0.28, 0.38, 1.0)
	},
	{
		"title": "instructions_tip_title",
		"body": "instructions_tip_body",
		"icon": "💡",
		"accent": Color(1.0, 0.88, 0.28, 1.0)
	}
]

func _ready() -> void:
	_apply_language()
	_build_cards()
	SettingsManager.apply_wooden_buttons(self)
	back_btn.pressed.connect(_on_back)

func _apply_language() -> void:
	title_label.text = SettingsManager.text("how_to_play")
	subtitle_label.text = SettingsManager.text("instructions_subtitle")
	back_btn.text = "← " + SettingsManager.text("back")

func _build_cards() -> void:
	for child in cards_host.get_children():
		child.queue_free()

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_host.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(grid)

	for card in CARD_DATA:
		grid.add_child(_create_card(card))

func _create_card(card: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 156)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 1.0, 0.86, 0.96)
	style.border_color = card["accent"]
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.03, 0.12, 0.03, 0.22)
	style.shadow_size = 10
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(68, 68)
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = card["accent"]
	icon_style.set_corner_radius_all(18)
	icon_box.add_theme_stylebox_override("panel", icon_style)
	row.add_child(icon_box)

	var icon_label := Label.new()
	icon_label.text = str(card["icon"])
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 34)
	icon_box.add_child(icon_label)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 8)
	row.add_child(text_box)

	var title := Label.new()
	title.text = SettingsManager.text(str(card["title"]))
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.08, 0.28, 0.08, 1.0))
	text_box.add_child(title)

	var body := Label.new()
	body.text = SettingsManager.text(str(card["body"]))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color(0.12, 0.18, 0.11, 1.0))
	text_box.add_child(body)

	return panel

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or _is_escape_key(event):
		_on_back()

func _is_escape_key(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE

func _on_back() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
