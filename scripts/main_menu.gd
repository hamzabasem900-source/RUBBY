extends Control

# يدير القائمة الرئيسية والمتجر ولوحة الجزر والتنقل بين المشاهد

# مراجع جاهزة لعقد المشهد حتى يتم تعديل النصوص والازرار والرسوم بسرعة
@onready var start_btn:   Button = $CenterContainer/VBoxContainer/StartButton
@onready var instr_btn:   Button = $CenterContainer/VBoxContainer/InstructionsButton
@onready var map_btn:     Button = $CenterContainer/VBoxContainer/LevelMapButton
@onready var quit_btn:    Button = $CenterContainer/VBoxContainer/QuitButton
@onready var settings_btn: Button = $SettingsButton
@onready var settings_hint: Label = $SettingsHint
@onready var title_label: Label  = $TitleLabel
@onready var subtitle_label: Label = $SubTitle
@onready var background: Sprite2D = $background

# متغيرات تحفظ حالة هذا السكربت اثناء اللعب
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

# يبدأ تجهيز هذا المشهد عند دخوله الى شجرة اللعبة
func _ready() -> void:
	AudioManager.play_menu_music()
	_prepare_responsive_layout()
	_build_reward_panel()
	_build_shop_overlay()
	_apply_language()
	_update_reward_panel(GameManager.carrot_wallet)
	_refresh_shop_cards()
	SettingsManager.apply_wooden_buttons(self)
	GameManager.carrot_wallet_changed.connect(_on_wallet_changed)
	GameManager.skin_collection_changed.connect(_refresh_shop_cards)
	GameManager.selected_skin_changed.connect(_on_selected_skin_changed)
	start_btn.pressed.connect(_on_start)
	instr_btn.pressed.connect(_on_instructions)
	map_btn.pressed.connect(_on_level_map)
	quit_btn.pressed.connect(_on_quit)
	settings_btn.pressed.connect(_on_settings)
	get_viewport().size_changed.connect(_on_viewport_size_changed)

# يربط تغييرات حجم النافذة بتحديث الخلفية
func _prepare_responsive_layout() -> void:
	_fit_background_to_viewport()
	_configure_top_labels()
	_configure_settings_shortcut(settings_btn)
	_configure_settings_shortcut(get_node_or_null("SettingsButton2") as Button)
	_configure_settings_hint()

# يحدث حجم الخلفية عندما يتغير حجم النافذة
func _on_viewport_size_changed() -> void:
	_fit_background_to_viewport()

# يمد الخلفية لتغطي مساحة العرض الحالية
func _fit_background_to_viewport() -> void:
	if background == null or background.texture == null:
		return
	var viewport_size := get_viewport_rect().size
	var texture_size := background.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var cover_scale: float = max(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	background.position = viewport_size * 0.5
	background.scale = Vector2(cover_scale, cover_scale)

# يضبط عناوين القائمة العلوية وشكلها
func _configure_top_labels() -> void:
	if title_label != null:
		title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		title_label.offset_left = 36.0
		title_label.offset_top = 34.0
		title_label.offset_right = -132.0
		title_label.offset_bottom = 120.0
	if subtitle_label != null:
		subtitle_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		subtitle_label.offset_left = 120.0
		subtitle_label.offset_top = 126.0
		subtitle_label.offset_right = -120.0
		subtitle_label.offset_bottom = 168.0

# يجهز زر الاعدادات المختصر في القائمة
func _configure_settings_shortcut(button: Button) -> void:
	if button == null:
		return
	button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = -102.0
	button.offset_top = 20.0
	button.offset_right = -30.0
	button.offset_bottom = 92.0

# يجهز تلميح الاعدادات الذي يظهر للاعب
func _configure_settings_hint() -> void:
	if settings_hint == null:
		return
	settings_hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	var hint_width: float = 136.0
	var button_center: float = (settings_btn.offset_left + settings_btn.offset_right) * 0.5
	settings_hint.offset_left = button_center - hint_width * 0.5
	settings_hint.offset_top = 94.0
	settings_hint.offset_right = button_center + hint_width * 0.5
	settings_hint.offset_bottom = 124.0
	settings_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	settings_hint.clip_text = false

# يلتقط ضغطات اللاعب العامة ويرسلها للاجراء المناسب
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if settings_btn.get_global_rect().has_point(mouse_event.position):
				open_settings()

# يحدث المنطق المتكرر في كل اطار عادي
func _process(delta: float) -> void:
	_bounce_t += delta
	if title_label:
		title_label.position.y = 28.0 + sin(_bounce_t * 1.6) * 6.0

# يطبق النصوص المناسبة للغة الحالية على عناصر الواجهة
func _apply_language() -> void:
	title_label.text = SettingsManager.text("app_title")
	subtitle_label.text = SettingsManager.text("main_subtitle")
	settings_hint.text = SettingsManager.text("settings")
	_apply_settings_hint_language_fit()
	start_btn.text = SettingsManager.text("start_game")
	instr_btn.text = SettingsManager.text("instructions")
	map_btn.text = SettingsManager.text("level_map")
	quit_btn.text = SettingsManager.text("quit")
	if _skin_button != null:
		_skin_button.text = SettingsManager.text("open_skin_shop")
	_refresh_shop_cards()

# يبني لوحة عرض رصيد الجزر وزر المتجر
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

# يبني نافذة المتجر التي تعرض الشخصيات
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

# ينشئ بطاقة شخصية واحدة داخل المتجر
func _create_skin_card(skin: Dictionary) -> PanelContainer:
	var skin_id := str(skin["id"])
	var accent: Color = skin["body_color"]
	var icon_tint := accent
	var icon_tint_value: Variant = skin.get("icon_tint", accent)
	if icon_tint_value is Color:
		icon_tint = icon_tint_value
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
	icon.modulate = icon_tint
	icon.add_theme_color_override("font_color", icon_tint)
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
		"button": action_btn
	}
	return card

# ينشئ شكل لوحة المكافات
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

# ينشئ شكل لوحة المتجر
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

# ينشئ شكل بطاقة الشخصية حسب لونها
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

# ينشئ شكل ايقونة الشخصية داخل البطاقة
func _skin_icon_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = accent.darkened(0.15)
	style.border_color = Color(1.0, 0.92, 0.48, 0.88)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	return style

# يختار رمز العرض المناسب للشخصية
func _skin_icon_text(skin: Dictionary) -> String:
	var badge := str(skin.get("badge", ""))
	return str(skin["icon"]) if badge == "" else str(skin["icon"]) + " " + badge

# يحدد حجم خط رمز الشخصية في البطاقة
func _skin_preview_font_size(skin: Dictionary) -> int:
	return int(clampf(42.0 * float(skin.get("visual_scale", 1.0)), 34.0, 50.0))

# يحدث لوحة الرصيد عند تغير عدد الجزر
func _on_wallet_changed(total: int) -> void:
	_update_reward_panel(total)
	_refresh_shop_cards()

# يحدث بطاقات المتجر عند تغيير الشخصية المختارة
func _on_selected_skin_changed(_skin_id: String) -> void:
	_update_reward_panel(GameManager.carrot_wallet)
	_refresh_shop_cards()

# يحدث نص رصيد الجزر في القائمة
func _update_reward_panel(total_carrots: int) -> void:
	var skin := GameManager.get_selected_skin_data()
	var skin_icon := _skin_icon_text(skin)
	if _wallet_label != null:
		_wallet_label.text = SettingsManager.format_text("carrot_wallet", {"count": total_carrots})
	if _bunny_preview != null:
		var preview_tint: Color = skin["body_color"]
		var preview_tint_value: Variant = skin.get("icon_tint", preview_tint)
		if preview_tint_value is Color:
			preview_tint = preview_tint_value
		_bunny_preview.text = skin_icon
		_bunny_preview.modulate = preview_tint
		_bunny_preview.add_theme_color_override("font_color", preview_tint)
		_bunny_preview.add_theme_font_size_override("font_size", _skin_preview_font_size(skin))
	if _skin_name_label != null:
		_skin_name_label.text = SettingsManager.text(str(skin["name_key"]))
	if _shop_wallet_label != null:
		_shop_wallet_label.text = SettingsManager.format_text("carrot_wallet", {"count": total_carrots})

# يفتح نافذة المتجر ويحدث بطاقاتها
func _open_shop() -> void:
	AudioManager.play_button_click()
	_shop_status_label.text = SettingsManager.text("skin_shop_hint")
	_shop_overlay.visible = true
	_refresh_shop_cards()

# يغلق نافذة المتجر
func _close_shop() -> void:
	AudioManager.play_button_click()
	_shop_overlay.visible = false

# ينفذ شراء او اختيار الشخصية عند ضغط بطاقتها
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

# يعيد بناء بطاقات المتجر حسب الحالة الحالية
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
		var preview_skin := GameManager.get_skin_data(skin_id)
		var icon_label := card["icon"] as Label
		var name_label := card["name"] as Label
		var description_label := card["description"] as Label
		var price_label := card["price"] as Label
		var icon_box := card["icon_box"] as PanelContainer
		icon_label.text = _skin_icon_text(preview_skin)
		icon_label.add_theme_font_size_override("font_size", _skin_preview_font_size(preview_skin))
		icon_box.add_theme_stylebox_override("panel", _skin_icon_style(preview_skin["body_color"]))
		name_label.text = SettingsManager.text(str(skin["name_key"]))
		description_label.text = SettingsManager.text(str(skin["description_key"]))
		price_label.text = SettingsManager.text("skin_owned") if owned else SettingsManager.format_text("skin_price", {"price": price})
		var button := card["button"] as Button
		button.disabled = selected
		if selected:
			button.text = SettingsManager.text("skin_selected")
		elif owned:
			button.text = SettingsManager.text("skin_equip")
		else:
			button.text = SettingsManager.text("skin_buy")

# يضبط حجم نص تلميح الاعدادات حسب اللغة
func _apply_settings_hint_language_fit() -> void:
	if settings_hint == null:
		return
	var language := str(SettingsManager.get_setting("language"))
	if language == "العربية":
		settings_hint.text_direction = Control.TEXT_DIRECTION_RTL
		settings_hint.language = "ar"
		settings_hint.add_theme_font_size_override("font_size", 15)
	else:
		settings_hint.text_direction = Control.TEXT_DIRECTION_AUTO
		settings_hint.language = ""
		settings_hint.add_theme_font_size_override("font_size", 16)

# يبدأ اللعب من شاشة اختيار الشخصية
func _on_start() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/LevelMap.tscn")

# يفتح شاشة التعليمات
func _on_instructions() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Instructions.tscn")

# يفتح خريطة المراحل
func _on_level_map() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/LevelMap.tscn")

# يفتح شاشة الاعدادات
func _on_settings() -> void:
	open_settings()

# يستدعي فتح شاشة الاعدادات من خارج المشهد
func open_settings() -> void:
	if _opening_settings:
		return
	_opening_settings = true
	AudioManager.play_button_click()
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

# يغلق اللعبة من القائمة الرئيسية
func _on_quit() -> void:
	AudioManager.play_button_click()
	get_tree().quit()
