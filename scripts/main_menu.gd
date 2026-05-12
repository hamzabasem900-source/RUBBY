extends Control

# =============================================
# MainMenu Scene Controller
# =============================================

@onready var start_btn:   Button = $CenterContainer/VBoxContainer/StartButton
@onready var instr_btn:   Button = $CenterContainer/VBoxContainer/InstructionsButton
@onready var map_btn:     Button = $CenterContainer/VBoxContainer/LevelMapButton
@onready var quit_btn:    Button = $CenterContainer/VBoxContainer/QuitButton
@onready var settings_btn: Button = $SettingsButton
@onready var settings_hint: Label = $SettingsHint
@onready var title_label: Label  = $TitleLabel
@onready var subtitle_label: Label = $SubTitle

var _bounce_t: float = 0.0
var _opening_settings: bool = false
var _wallet_label: Label
var _bunny_preview: Label
var _skin_name_label: Label
var _skin_button: Button
var _shop_overlay: Control
var _shop_wallet_label: Label
var _shop_status_label: Label
var _skin_cards: Dictionary = {}

func _ready() -> void:
	AudioManager.play_menu_music()
	_build_reward_panel()
	_build_shop_overlay()
	_apply_language()
	_update_reward_panel(GameManager.carrot_wallet)
	_refresh_shop_cards()
	SettingsManager.apply_wooden_buttons(self)
	GameManager.carrot_wallet_changed.connect(_on_wallet_changed)
	GameManager.skin_collection_changed.connect(_refresh_shop_cards)
	GameManager.skin_colors_changed.connect(_refresh_shop_cards)
	GameManager.selected_skin_changed.connect(_on_selected_skin_changed)
	start_btn.pressed.connect(_on_start)
	instr_btn.pressed.connect(_on_instructions)
	map_btn.pressed.connect(_on_level_map)
	quit_btn.pressed.connect(_on_quit)
	settings_btn.pressed.connect(_on_settings)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if settings_btn.get_global_rect().has_point(mouse_event.position):
				open_settings()

func _process(delta: float) -> void:
	_bounce_t += delta
	if title_label:
		title_label.position.y = 28.0 + sin(_bounce_t * 1.6) * 6.0

func _apply_language() -> void:
	title_label.text = SettingsManager.text("app_title")
	subtitle_label.text = SettingsManager.text("main_subtitle")
	settings_hint.text = SettingsManager.text("settings")
	start_btn.text = SettingsManager.text("start_game")
	instr_btn.text = SettingsManager.text("instructions")
	map_btn.text = SettingsManager.text("level_map")
	quit_btn.text = SettingsManager.text("quit")
	if _skin_button != null:
		_skin_button.text = SettingsManager.text("open_skin_shop")
	_refresh_shop_cards()

func _build_reward_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "RewardPanel"
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -230
	panel.offset_top = 328
	panel.offset_right = -28
	panel.offset_bottom = -28
	panel.add_theme_stylebox_override("panel", _reward_panel_style())
	add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	_bunny_preview = Label.new()
	_bunny_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bunny_preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bunny_preview.custom_minimum_size = Vector2(154, 78)
	_bunny_preview.add_theme_font_size_override("font_size", 52)
	box.add_child(_bunny_preview)

	_skin_name_label = Label.new()
	_skin_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skin_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_skin_name_label.add_theme_font_size_override("font_size", 18)
	_skin_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.82, 1.0))
	box.add_child(_skin_name_label)

	_wallet_label = Label.new()
	_wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wallet_label.add_theme_font_size_override("font_size", 24)
	_wallet_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.52, 1.0))
	box.add_child(_wallet_label)

	_skin_button = Button.new()
	_skin_button.custom_minimum_size = Vector2(158, 48)
	_skin_button.pressed.connect(_open_shop)
	box.add_child(_skin_button)

func _build_shop_overlay() -> void:
	_shop_overlay = Control.new()
	_shop_overlay.name = "SkinShopOverlay"
	_shop_overlay.visible = false
	_shop_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shop_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_shop_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shop_overlay.add_child(dim)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 70)
	root.add_theme_constant_override("margin_right", 70)
	root.add_theme_constant_override("margin_top", 58)
	root.add_theme_constant_override("margin_bottom", 50)
	_shop_overlay.add_child(root)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _shop_panel_style())
	root.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	panel.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := Label.new()
	title.text = SettingsManager.text("skin_shop_title")
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1.0))
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = SettingsManager.text("skin_shop_subtitle")
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.86, 1.0, 0.82, 1.0))
	title_box.add_child(subtitle)

	_shop_wallet_label = Label.new()
	_shop_wallet_label.custom_minimum_size = Vector2(160, 42)
	_shop_wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_wallet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_shop_wallet_label.add_theme_font_size_override("font_size", 26)
	_shop_wallet_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.52, 1.0))
	header.add_child(_shop_wallet_label)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(54, 46)
	close_btn.pressed.connect(_close_shop)
	header.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)

	for skin in GameManager.get_skin_catalog():
		grid.add_child(_create_skin_card(skin))

	_shop_status_label = Label.new()
	_shop_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_status_label.add_theme_font_size_override("font_size", 18)
	_shop_status_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.64, 1.0))
	layout.add_child(_shop_status_label)

	SettingsManager.apply_wooden_buttons(_shop_overlay)

func _create_skin_card(skin: Dictionary) -> PanelContainer:
	var skin_id := str(skin["id"])
	var accent: Color = skin["body_color"]
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(390, 176)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _skin_card_style(accent))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(86, 96)
	icon_box.add_theme_stylebox_override("panel", _skin_icon_style(accent))
	row.add_child(icon_box)

	var icon := Label.new()
	icon.text = _skin_icon_text(skin)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", _skin_preview_font_size(skin))
	icon_box.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)

	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.78, 1.0))
	info.add_child(name_label)

	var description_label := Label.new()
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 15)
	description_label.add_theme_color_override("font_color", Color(0.86, 1.0, 0.84, 1.0))
	info.add_child(description_label)

	var price_label := Label.new()
	price_label.add_theme_font_size_override("font_size", 18)
	price_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.40, 1.0))
	info.add_child(price_label)

	var color_row := HBoxContainer.new()
	color_row.add_theme_constant_override("separation", 7)
	info.add_child(color_row)

	var color_buttons: Dictionary = {}
	for color in GameManager.get_color_variants(skin_id):
		var color_id := str(color["id"])
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(30, 30)
		swatch.focus_mode = Control.FOCUS_NONE
		swatch.pressed.connect(Callable(self, "_on_skin_color_pressed").bind(skin_id, color_id))
		color_row.add_child(swatch)
		color_buttons[color_id] = swatch

	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(132, 50)
	action_btn.pressed.connect(func() -> void:
		_on_skin_action_pressed(skin_id)
	)
	row.add_child(action_btn)

	_skin_cards[skin_id] = {
		"icon": icon,
		"icon_box": icon_box,
		"name": name_label,
		"description": description_label,
		"price": price_label,
		"colors": color_buttons,
		"button": action_btn
	}
	return card

func _reward_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.16, 0.07, 0.58)
	style.border_color = Color(0.98, 0.80, 0.24, 0.86)
	style.set_border_width_all(3)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _shop_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.16, 0.07, 0.97)
	style.border_color = Color(0.88, 0.68, 0.28, 1.0)
	style.set_border_width_all(4)
	style.set_corner_radius_all(30)
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 18
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	return style

func _skin_card_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.23, 0.10, 0.95)
	style.border_color = accent.lightened(0.20)
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func _skin_icon_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = accent.darkened(0.15)
	style.border_color = Color(1.0, 0.92, 0.48, 0.88)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	return style

func _skin_icon_text(skin: Dictionary) -> String:
	var badge := str(skin.get("badge", ""))
	return str(skin["icon"]) if badge == "" else str(skin["icon"]) + " " + badge

func _skin_preview_font_size(skin: Dictionary) -> int:
	return int(clampf(42.0 * float(skin.get("visual_scale", 1.0)), 34.0, 50.0))

func _on_wallet_changed(total: int) -> void:
	_update_reward_panel(total)
	_refresh_shop_cards()

func _on_selected_skin_changed(_skin_id: String) -> void:
	_update_reward_panel(GameManager.carrot_wallet)
	_refresh_shop_cards()

func _update_reward_panel(total_carrots: int) -> void:
	var skin := GameManager.get_selected_skin_data()
	var skin_icon := _skin_icon_text(skin)
	if _wallet_label != null:
		_wallet_label.text = SettingsManager.format_text("carrot_wallet", {"count": total_carrots})
	if _bunny_preview != null:
		_bunny_preview.text = skin_icon
		_bunny_preview.add_theme_font_size_override("font_size", _skin_preview_font_size(skin))
	if _skin_name_label != null:
		_skin_name_label.text = SettingsManager.text(str(skin["name_key"]))
	if _shop_wallet_label != null:
		_shop_wallet_label.text = SettingsManager.format_text("carrot_wallet", {"count": total_carrots})

func _open_shop() -> void:
	AudioManager.play_button_click()
	_shop_status_label.text = SettingsManager.text("skin_shop_hint")
	_shop_overlay.visible = true
	_refresh_shop_cards()

func _close_shop() -> void:
	AudioManager.play_button_click()
	_shop_overlay.visible = false

func _on_skin_action_pressed(skin_id: String) -> void:
	AudioManager.play_button_click()
	if GameManager.is_skin_owned(skin_id):
		GameManager.equip_skin(skin_id)
		_shop_status_label.text = SettingsManager.format_text("skin_equipped_status", {"name": SettingsManager.text(str(GameManager.get_skin_data(skin_id)["name_key"]))})
	elif GameManager.purchase_skin(skin_id):
		_shop_status_label.text = SettingsManager.format_text("skin_bought_status", {"name": SettingsManager.text(str(GameManager.get_skin_data(skin_id)["name_key"]))})
	else:
		_shop_status_label.text = SettingsManager.text("skin_not_enough")
	_refresh_shop_cards()

func _on_skin_color_pressed(skin_id: String, color_id: String) -> void:
	AudioManager.play_button_click()
	if not GameManager.is_skin_owned(skin_id):
		_shop_status_label.text = SettingsManager.text("color_unlock_skin_first")
		return
	var color := GameManager.get_color_variant(color_id)
	var color_name := SettingsManager.text(str(color["name_key"]))
	if GameManager.purchase_or_equip_skin_color(skin_id, color_id):
		if GameManager.is_skin_color_owned(skin_id, color_id):
			_shop_status_label.text = SettingsManager.format_text("color_selected_status", {"color": color_name})
	else:
		_shop_status_label.text = SettingsManager.text("color_not_enough")
	_refresh_shop_cards()

func _refresh_color_buttons(skin_id: String, color_buttons: Dictionary, skin_owned: bool) -> void:
	var selected_color := GameManager.get_selected_color_id(skin_id)
	for color in GameManager.get_color_variants(skin_id):
		var color_id := str(color["id"])
		if not color_buttons.has(color_id):
			continue
		var button := color_buttons[color_id] as Button
		var owned := skin_owned and GameManager.is_skin_color_owned(skin_id, color_id)
		var is_selected := skin_owned and selected_color == color_id
		button.disabled = not skin_owned
		button.text = "✓" if is_selected else ("" if owned else "🔒")
		button.tooltip_text = _color_tooltip(color, owned, is_selected)
		var body_color: Color = color["body_color"]
		button.add_theme_stylebox_override("normal", _color_swatch_style(body_color, is_selected, owned))
		button.add_theme_stylebox_override("hover", _color_swatch_style(body_color.lightened(0.10), true, owned))
		button.add_theme_stylebox_override("pressed", _color_swatch_style(body_color.darkened(0.08), true, owned))
		button.add_theme_color_override("font_color", Color(0.07, 0.12, 0.07, 1.0) if body_color.get_luminance() > 0.55 else Color.WHITE)

func _color_tooltip(color: Dictionary, owned: bool, is_selected: bool) -> String:
	var color_name := SettingsManager.text(str(color["name_key"]))
	if is_selected:
		return SettingsManager.format_text("color_selected_tooltip", {"color": color_name})
	if owned:
		return SettingsManager.format_text("color_owned_tooltip", {"color": color_name})
	return SettingsManager.format_text("color_price", {"color": color_name, "price": int(color["price"])})

func _color_swatch_style(color: Color, selected: bool, owned: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color if owned else color.darkened(0.45)
	style.border_color = Color(1.0, 0.94, 0.36, 1.0) if selected else Color(0.84, 0.94, 0.74, 0.75)
	style.set_border_width_all(3 if selected else 1)
	style.set_corner_radius_all(9)
	return style

func _refresh_shop_cards() -> void:
	_update_reward_panel(GameManager.carrot_wallet)
	for skin in GameManager.get_skin_catalog():
		var skin_id := str(skin["id"])
		if not _skin_cards.has(skin_id):
			continue
		var card: Dictionary = _skin_cards[skin_id]
		var price := int(skin["price"])
		var owned := GameManager.is_skin_owned(skin_id)
		var selected := GameManager.selected_character == skin_id
		var selected_color := GameManager.get_selected_color_id(skin_id)
		var preview_skin := GameManager.get_skin_preview_data(skin_id, selected_color)
		var icon_label := card["icon"] as Label
		var name_label := card["name"] as Label
		var description_label := card["description"] as Label
		var price_label := card["price"] as Label
		var icon_box := card["icon_box"] as PanelContainer
		var color_buttons: Dictionary = card["colors"]
		icon_label.text = _skin_icon_text(preview_skin)
		icon_label.add_theme_font_size_override("font_size", _skin_preview_font_size(preview_skin))
		icon_box.add_theme_stylebox_override("panel", _skin_icon_style(preview_skin["body_color"]))
		name_label.text = SettingsManager.text(str(skin["name_key"]))
		description_label.text = SettingsManager.text(str(skin["description_key"]))
		price_label.text = SettingsManager.text("skin_owned") if owned else SettingsManager.format_text("skin_price", {"price": price})
		_refresh_color_buttons(skin_id, color_buttons, owned)
		var button := card["button"] as Button
		button.disabled = selected
		if selected:
			button.text = SettingsManager.text("skin_selected")
		elif owned:
			button.text = SettingsManager.text("skin_equip")
		else:
			button.text = SettingsManager.text("skin_buy")

func _on_start() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/LevelMap.tscn")

func _on_instructions() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Instructions.tscn")

func _on_level_map() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/LevelMap.tscn")

func _on_settings() -> void:
	open_settings()

func open_settings() -> void:
	if _opening_settings:
		return
	_opening_settings = true
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_quit() -> void:
	AudioManager.play_button_click()
	get_tree().quit()
