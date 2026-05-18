extends Node

# =============================================
# SettingsManager — AutoLoad Singleton
# Saves player preferences and applies global presentation settings.
# =============================================

signal settings_changed
signal language_changed(language: String)

const CONFIG_PATH: String = "user://settings.cfg"
const SECTION: String = "game"
const DESIGN_SIZE := Vector2i(1024, 720)

const DEFAULT_SETTINGS: Dictionary = {
	"master_volume": 0.85,
	"music_volume": 0.70,
	"sfx_volume": 0.85,
	"mute_audio": false,
	"language": "العربية",
	"resolution": "1280 x 720",
	"difficulty": "Normal"
}

var values: Dictionary = DEFAULT_SETTINGS.duplicate(true)

func _ready() -> void:
	load_settings()
	apply_all()

func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	if err != OK:
		return
	for key in DEFAULT_SETTINGS.keys():
		values[key] = config.get_value(SECTION, key, DEFAULT_SETTINGS[key])
	_sanitize_settings()

func _sanitize_settings() -> void:
	values["language"] = str(DEFAULT_SETTINGS["language"])
	if not ["1024 x 720", "1280 x 720", "1600 x 900", "1920 x 1080"].has(str(values["resolution"])):
		values["resolution"] = str(DEFAULT_SETTINGS["resolution"])

func save_settings() -> void:
	var config := ConfigFile.new()
	for key in values.keys():
		config.set_value(SECTION, key, values[key])
	var err := config.save(CONFIG_PATH)
	if err != OK:
		push_warning("SettingsManager: could not save settings file.")

func reset_to_defaults() -> void:
	values = DEFAULT_SETTINGS.duplicate(true)
	_sanitize_settings()
	apply_all()
	save_settings()
	settings_changed.emit()
	language_changed.emit(str(values["language"]))

func set_setting(key: String, value: Variant, save_now: bool = true) -> void:
	if not DEFAULT_SETTINGS.has(key):
		push_warning("SettingsManager: unknown setting — " + key)
		return
	var old_language := str(values["language"])
	values[key] = value
	_sanitize_settings()
	apply_all()
	if save_now:
		save_settings()
	settings_changed.emit()
	if key == "language" and old_language != str(values["language"]):
		language_changed.emit(str(values["language"]))

func get_setting(key: String) -> Variant:
	return values.get(key, DEFAULT_SETTINGS.get(key))

func apply_all() -> void:
	apply_window_settings()
	apply_audio_settings()

func apply_window_settings() -> void:
	var window := get_window()
	window.content_scale_size = DESIGN_SIZE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE

	_apply_windowed_size(_resolution_to_vector(str(values["resolution"])))

func _apply_windowed_size(size: Vector2i) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_size(size)
	get_window().size = size
	_center_window(size)
	call_deferred("_finish_windowed_size_apply", size)

func _finish_windowed_size_apply(size: Vector2i) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(size)
	get_window().size = size
	_center_window(size)

func _center_window(size: Vector2i) -> void:
	var screen_size := DisplayServer.screen_get_size()
	var centered_position := Vector2i(
		int((screen_size.x - size.x) / 2.0),
		int((screen_size.y - size.y) / 2.0)
	)
	DisplayServer.window_set_position(centered_position)

func apply_audio_settings() -> void:
	_set_bus_volume("Master", float(values["master_volume"]), bool(values["mute_audio"]))
	_set_bus_volume("Music", float(values["music_volume"]), bool(values["mute_audio"]))
	_set_bus_volume("SFX", float(values["sfx_volume"]), bool(values["mute_audio"]))

func _set_bus_volume(bus_name: String, linear_value: float, muted: bool) -> void:
	_ensure_audio_bus(bus_name)
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	AudioServer.set_bus_mute(bus_idx, muted)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clamp(linear_value, 0.0, 1.0)))

func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(idx, bus_name)

func _resolution_to_vector(resolution: String) -> Vector2i:
	match resolution:
		"1024 x 720":
			return Vector2i(1024, 720)
		"1600 x 900":
			return Vector2i(1600, 900)
		"1920 x 1080":
			return Vector2i(1920, 1080)
		_:
			return Vector2i(1280, 720)

func apply_wooden_buttons(root: Node) -> void:
	for child in root.get_children():
		if child is Button and not (child is CheckButton):
			style_wooden_button(child as Button)
		apply_wooden_buttons(child)

func style_wooden_button(button: Button, font_color: Color = Color.WHITE) -> void:
	button.add_theme_font_size_override("font_size", int(max(22, button.get_theme_font_size("font_size"))))
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.78, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.86, 0.55, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.58, 0.44, 0.32, 1.0))
	button.add_theme_color_override("font_outline_color", Color(0.20, 0.10, 0.05, 1.0))
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_stylebox_override("normal", _wood_style(Color(0.63, 0.36, 0.18, 1.0), Color(0.28, 0.13, 0.06, 1.0)))
	button.add_theme_stylebox_override("hover", _wood_style(Color(0.74, 0.44, 0.22, 1.0), Color(0.36, 0.17, 0.07, 1.0)))
	button.add_theme_stylebox_override("pressed", _wood_style(Color(0.47, 0.25, 0.12, 1.0), Color(0.20, 0.09, 0.04, 1.0)))
	button.add_theme_stylebox_override("disabled", _wood_style(Color(0.36, 0.25, 0.17, 0.82), Color(0.18, 0.11, 0.07, 0.92)))
	button.add_theme_stylebox_override("focus", _wood_focus_style())

func _wood_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.10, 0.04, 0.02, 0.42)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _wood_focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(1.0, 0.86, 0.30, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	return style

func text(key: String) -> String:
	var arabic := {
		"settings": "الإعدادات",
		"settings_subtitle": "غير ما تريد بسهولة.",
		"audio": "الصوت",
		"master_volume": "الصوت الرئيسي",
		"music_volume": "الموسيقى",
		"sfx_volume": "المؤثرات",
		"mute_audio": "كتم الصوت",
		"language": "اللغة",
		"gameplay": "اللعب",
		"difficulty": "الصعوبة",
		"visuals": "العرض",
		"resolution": "الدقة",
		"windowed": "نافذة",
		"reset": "استعادة الافتراضي",
		"back": "رجوع",
		"back_to_menu": "رجوع للقائمة",
		"preview": "معاينة مباشرة",
		"level_times": "أوقات المراحل",
		"app_title": "🥕 مغامرة الأرنب والجزر 🐰",
		"main_subtitle": "اجمع الجزر وابتعد عن الثعالب والخطر!",
		"carrot_wallet": "🥕 {count}",
		"open_skin_shop": "الاشكال",
		"skin_shop_title": "🥕 متجر اشكال الارنب",
		"skin_shop_subtitle": "اشتر شكلا جديدا بالجزر ثم اختره.",
		"skin_shop_hint": "اجمع الجزر في المراحل ثم عد لشراء اشكال جديدة.",
		"skin_price": "السعر: {price} 🥕",
		"skin_owned": "مملوك",
		"skin_buy": "شراء",
		"skin_equip": "اختيار",
		"skin_selected": "مختار",
		"skin_not_enough": "الجزر غير كاف بعد.",
		"skin_bought_status": "تم شراء واختيار {name}!",
		"skin_equipped_status": "تم اختيار {name}.",
		"skin_white_name": "الكلاسيكي",
		"skin_white_desc": "شكل الارنب الاساسي وجاهز للجزر.",
		"skin_runner_name": "القافز",
		"skin_runner_desc": "شكل الارنب السابق الجانبي وجاهز للقفز.",
		"skin_dune_name": "أرنب الصحراء",
		"skin_dune_desc": "أرنب طويل بأذنين طويلتين وجسم رشيق وحركة سريعة.",
		"skin_snow_name": "كشاف الثلج",
		"skin_snow_desc": "أرنب أبيض صغير بجسم مستدير وتصادم أصغر للممرات الضيقة.",
		"choose_bunny": "اختر الأرنب! 🐰",
		"white_bunny_button": "🐰 الأرنب الكلاسيكي",
		"brown_bunny_button": "🐇 الأرنب القافز",
		"select_dune_bunny_button": "🐇 أرنب الصحراء",
		"select_snow_bunny_button": "🐰 كشاف الثلج",
		"confirm_play": "✔ هيا نلعب!",
		"skin_meadow_name": "وشاح اخضر",
		"skin_meadow_desc": "ارنب مع وشاح اخضر بسيط.",
		"skin_rose_name": "ربطة ورد",
		"skin_rose_desc": "ارنب مع ربطة وردية جميلة.",
		"skin_golden_name": "الذهبي",
		"skin_golden_desc": "ارنب ذهبي لامع لمحبي الجزر.",
		"skin_night_name": "الليل",
		"skin_night_desc": "ارنب داكن مع قمر صغير.",
		"skin_tiny_name": "ارنب صغير",
		"skin_tiny_desc": "ارنب صغير يناسب الطرق الضيقة.",
		"skin_lop_name": "ارنب طويل الاذن",
		"skin_lop_desc": "ارنب طويل بأذنين طويلتين.",
		"skin_spotted_name": "ارنب الطريق المرقط",
		"skin_spotted_desc": "ارنب بني وابيض مميز مع انميشن قفز خاص به.",
		"start_game": "▶  ابدأ اللعب",
		"instructions": "📖  التعليمات",
		"level_map": "🗺  خريطة المراحل",
		"quit": "✖  خروج",
		"how_to_play": "📖 طريقة اللعب",
		"instructions_subtitle": "نصائح سريعة للعب بسهولة.",
		"instructions_controls_title": "الحركة",
		"instructions_controls_body": "استخدم الاسهم او WASD للتحرك. اضغط Space او Enter للاندفاع.",
		"instructions_collect_title": "اجمع الجزر",
		"instructions_collect_body": "الجزرة البرتقالية تعطي 10 نقاط. الجزرة الذهبية تعطي 25 نقطة، فاجمعها أولا عندما يكون الطريق آمنا.",
		"instructions_hazards_title": "المخاطر",
		"instructions_hazards_body": "الثعالب تطاردك. الحفر والشوك تنقص حياة واحدة.",
		"instructions_goal_title": "افز بالمرحلة",
		"instructions_goal_body": "اجمع النقاط المطلوبة قبل نهاية الوقت لتفتح المرحلة التالية.",
		"instructions_lives_title": "احم القلوب",
		"instructions_lives_body": "اذا انتهت القلوب تنتهي المحاولة.",
		"instructions_tip_title": "نصيحة",
		"instructions_tip_body": "ابتعد عن الخطر واستخدم الاندفاع عند الحاجة.",
		"instructions_body": "[b]🎮 التحكم:[/b]\n  الأسهم أو WASD — حرك الأرنب\n  Space أو Enter — اندفاع سريع\n\n[b]🥕 التجميع:[/b]\n  الجزرة البرتقالية = 10 نقاط\n  الجزرة الذهبية = 25 نقطة\n\n[b]⚠ المخاطر:[/b]\n  🦊 الثعالب — تطارد الأرنب وتنقص حياة واحدة.\n  🕳 جحور/حفر الأرض — حفرة بيضاوية داكنة حولها تراب؛ لا تدخل فيها.\n  🌿 شجيرات الشوك — شجيرات خضراء عليها أشواك فاتحة؛ لمسها ينقص حياة واحدة.\n\n[b]🎯 الهدف:[/b]\n  اجمع نقاطا كافية قبل انتهاء الوقت!\n  وصل للنقاط المطلوبة كي تفوز بالمرحلة.\n\n[b]❤ الحيوات:[/b]\n  تبدأ بثلاث حيوات. كل إصابة تنقص حياة.\n  إذا وصلت الحيوات إلى صفر تنتهي اللعبة!",
		"map_title": "خريطة مغامرة الحديقة",
		"level1_name": "🌱 1\nالحديقة السهلة",
		"level2_name": "🌻 2\nممر الثعلب",
		"level3_name": "🌿 3\nتلة الشوك",
		"level1_lock": "🔒 افز بالمرحلة 1",
		"level2_lock": "🔒 افز بالمرحلة 2",
		"map_legend": "اتبع الطريق:\nاجمع الجزر ← افتح مناطق جديدة",
		"level": "المرحلة",
		"seconds_suffix": "ث",
		"dash_tip": "اندفاع: Space / Enter",
		"pause_button_hint": "إيقاف مؤقت",
		"pause_title": "⏸ إيقاف مؤقت",
		"pause_subtitle": "اللعبة متوقفة حتى تكمل اللعب.",
		"pause_resume": "▶ استئناف",
		"pause_restart": "🔄 إعادة المرحلة",
		"pause_lobby": "🏠 العودة للقائمة",
		"pause_quit": "✖ الخروج من اللعبة",
		"win_banner": "🎉 فزت! 🎉",
		"final_score": "النقاط النهائية: {score} 🥕",
		"carrots_banked": "الجزر المحفوظ: +{count} 🥕",
		"next_level": "➡ المرحلة التالية",
		"play_again": "🔄 العب مجددا",
		"main_menu": "🏠 القائمة الرئيسية",
		"all_levels_complete": "🎉 انتهت كل المراحل!",
		"win_message_1": "عمل رائع! 🌟",
		"win_message_2": "أنت بطل الجزر! 🥕",
		"win_message_3": "أرنب ذكي! 🐰",
		"win_message_4": "رائع جدا! ⭐",
		"win_message_5": "قفزة رائعة! اكمل! 🎉",
		"game_over_banner": "😢 انتهت اللعبة!",
		"game_over_score": "حصلت على: {score} نقطة",
		"try_again": "🔄 حاول مرة أخرى!",
		"game_over_message_1": "لا تستسلم يا ارنب! 🐰",
		"game_over_message_2": "كنت قريبا! حاول مرة أخرى! 💪",
		"game_over_message_3": "الجزر ينتظرك! 🥕",
		"game_over_message_4": "تستطيع الفوز! حاول مرة اخرى! 🌟",
		"result_title": "نتيجة المرحلة",
		"your_score": "نقاطك: {score}",
		"time_used": "الوقت المستخدم: {time}ث",
		"retry": "🔄 إعادة المحاولة",
		"easy": "سهل",
		"normal": "عادي",
		"hard": "صعب"
	}
	return str(arabic.get(key, key))

func format_text(key: String, replacements: Dictionary) -> String:
	var formatted := text(key)
	for token in replacements.keys():
		formatted = formatted.replace("{" + str(token) + "}", str(replacements[token]))
	return formatted

func option_text(setting_key: String, value: String) -> String:
	if setting_key != "difficulty":
		return value
	match value:
		"Easy":
			return text("easy")
		"Hard":
			return text("hard")
		_:
			return text("normal")
