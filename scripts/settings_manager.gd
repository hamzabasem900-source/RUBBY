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
	"language": "English",
	"fullscreen": true,
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

func save_settings() -> void:
	var config := ConfigFile.new()
	for key in values.keys():
		config.set_value(SECTION, key, values[key])
	var err := config.save(CONFIG_PATH)
	if err != OK:
		push_warning("SettingsManager: could not save settings file.")

func reset_to_defaults() -> void:
	values = DEFAULT_SETTINGS.duplicate(true)
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
	apply_all()
	if save_now:
		save_settings()
	settings_changed.emit()
	if key == "language" and old_language != str(value):
		language_changed.emit(str(value))

func get_setting(key: String) -> Variant:
	return values.get(key, DEFAULT_SETTINGS.get(key))

func apply_all() -> void:
	apply_window_settings()
	apply_audio_settings()

func apply_window_settings() -> void:
	var size := _resolution_to_vector(str(values["resolution"]))
	var window := get_window()
	window.content_scale_size = DESIGN_SIZE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

	var fullscreen: bool = bool(values["fullscreen"])
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if not fullscreen:
		DisplayServer.window_set_size(size)
		var screen_size := DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size - size) / 2)

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
	var language := str(values["language"])
	var english := {
		"settings": "Settings",
		"settings_subtitle": "Tune your adventure exactly the way you like.",
		"audio": "Audio",
		"master_volume": "Master Volume",
		"music_volume": "Music Volume",
		"sfx_volume": "SFX Volume",
		"mute_audio": "Mute all sound",
		"language": "Language",
		"gameplay": "Gameplay",
		"difficulty": "Difficulty",
		"visuals": "Display",
		"fullscreen": "Fullscreen",
		"resolution": "Resolution",
		"reset": "Reset Defaults",
		"back": "Back",
		"back_to_menu": "Back to Menu",
		"preview": "Live Preview",
		"on": "ON",
		"off": "OFF",
		"app_title": "🥕 Bunny Carrot Adventure 🐰",
		"main_subtitle": "Collect carrots, avoid foxes, dash past danger!",
		"carrot_wallet": "🥕 {count}",
		"open_skin_shop": "Skins",
		"skin_shop_title": "🥕 Bunny Skin Shop",
		"skin_shop_subtitle": "Buy bunny outfits and accessories with saved carrots, then equip your favorite.",
		"skin_shop_hint": "Collect carrots in levels, win, then come back for new skins.",
		"skin_price": "Price: {price} 🥕",
		"skin_owned": "Owned",
		"skin_buy": "Buy",
		"skin_equip": "Equip",
		"skin_selected": "Selected",
		"skin_not_enough": "Not enough carrots yet.",
		"skin_bought_status": "Purchased and equipped {name}!",
		"skin_equipped_status": "Equipped {name}.",
		"skin_white_name": "Classic White",
		"skin_white_desc": "The original brave bunny look. Always ready for carrots.",
		"skin_brown_name": "Cocoa Bunny",
		"skin_brown_desc": "Warm brown fur for a cozy garden adventure.",
		"skin_meadow_name": "Meadow Scarf",
		"skin_meadow_desc": "A bunny outfit with a leafy scarf for garden camouflage.",
		"skin_rose_name": "Rose Bow",
		"skin_rose_desc": "A bunny look with a soft rose bow for spring adventures.",
		"skin_golden_name": "Golden Vest",
		"skin_golden_desc": "A bright golden bunny vest made for true carrot collectors.",
		"skin_night_name": "Moon Cape",
		"skin_night_desc": "A dark bunny cape with a moon badge for quiet night runs.",
		"start_game": "▶  Start Game",
		"instructions": "📖  Instructions",
		"level_map": "🗺  Level Map",
		"quit": "✖  Quit",
		"how_to_play": "📖 How To Play",
		"instructions_subtitle": "Quick guide cards for a safer carrot adventure.",
		"instructions_controls_title": "Move like a pro",
		"instructions_controls_body": "Use Arrow Keys or WASD to move. Press Space or Enter for a quick dash when danger gets close.",
		"instructions_collect_title": "Collect carrots",
		"instructions_collect_body": "Orange carrots give 10 points. Golden carrots give 25 points, so grab them first when it is safe.",
		"instructions_hazards_title": "Know the hazards",
		"instructions_hazards_body": "Foxes chase you. Burrow holes are dark dirt pits. Thorn bushes are green shrubs with pale spikes. Any hit costs 1 life.",
		"instructions_goal_title": "Win the level",
		"instructions_goal_body": "Reach the required score before time runs out. Collect enough carrots to unlock the next garden area.",
		"instructions_lives_title": "Protect your lives",
		"instructions_lives_body": "You start with the lives shown at the top of the screen. If they reach zero, the run ends.",
		"instructions_tip_title": "Smart bunny tip",
		"instructions_tip_body": "Plan your route around hazards, dash only when needed, and go for golden carrots when the path is clear.",
		"instructions_body": "[b]🎮 Controls:[/b]\n  Arrow Keys or WASD — Move your bunny\n  Space or Enter — Quick dash burst\n\n[b]🥕 Collect:[/b]\n  Orange Carrot = 10 points\n  Golden Carrot = 25 points\n\n[b]⚠ Hazards:[/b]\n  🦊 Foxes — they chase the bunny and cost 1 life.\n  🕳 Burrow Holes — dark oval pits with a dirt rim; avoid stepping into them.\n  🌿 Thorn Bushes — green bushes with pale spikes; touching them costs 1 life.\n\n[b]🎯 Goal:[/b]\n  Collect enough points before the timer ends!\n  Reach the required score to win the level.\n\n[b]❤ Lives:[/b]\n  You start with 3 lives. Each hit = -1 life.\n  If lives reach 0, it's Game Over!",
		"choose_bunny": "Choose Your Bunny! 🐰",
		"white_bunny": "White Bunny 🐰",
		"brown_bunny": "Brown Bunny 🐰",
		"white_bunny_button": "⬜ White Bunny",
		"brown_bunny_button": "🟫 Brown Bunny",
		"confirm_play": "✔ Let's Go! Play!",
		"map_title": "🗺 Real Garden Adventure Map",
		"level1_name": "🌱 1\nEasy Garden",
		"level2_name": "🌻 2\nFox Crossing",
		"level3_name": "🌿 3\nThorny Hill",
		"level1_lock": "🔒 Win Level 1",
		"level2_lock": "🔒 Win Level 2",
		"map_legend": "Follow the trail:\nCollect carrots → unlock areas",
		"level": "Level",
		"seconds_suffix": "s",
		"dash_tip": "Dash: Space / Enter",
		"pause_button_hint": "Pause",
		"pause_title": "⏸ Paused",
		"pause_subtitle": "Take a breath — your bunny is safe until you resume.",
		"pause_resume": "▶ Resume",
		"pause_restart": "🔄 Restart Level",
		"pause_lobby": "🏠 Back to Lobby",
		"pause_quit": "✖ Exit Game",
		"win_banner": "🎉 YOU WIN! 🎉",
		"final_score": "Final Score: {score} 🥕",
		"carrots_banked": "Saved carrots: +{count} 🥕",
		"next_level": "➡ Next Level",
		"play_again": "🔄 Play Again",
		"main_menu": "🏠 Main Menu",
		"all_levels_complete": "🎉 All Levels Complete!",
		"win_message_1": "Amazing job! 🌟",
		"win_message_2": "You're a carrot champion! 🥕",
		"win_message_3": "Brilliant bunny! 🐰",
		"win_message_4": "Wow, you're unstoppable! ⭐",
		"win_message_5": "Super hop! Keep going! 🎉",
		"game_over_banner": "😢 Oh No!",
		"game_over_score": "You got: {score} points",
		"try_again": "🔄 Try Again!",
		"game_over_message_1": "Oops! Don't give up, little bunny! 🐰",
		"game_over_message_2": "So close! Try again! 💪",
		"game_over_message_3": "The carrots are waiting for you! 🥕",
		"game_over_message_4": "You can do it! One more hop! 🌟",
		"result_title": "Level Results! 🥕",
		"your_score": "Your Score: {score}",
		"time_used": "Time Used: {time}s",
		"retry": "🔄 Retry",
		"easy": "Easy",
		"normal": "Normal",
		"hard": "Hard"
	}
	var arabic := {
		"settings": "الإعدادات",
		"settings_subtitle": "اضبط اللعبة بالطريقة التي تناسبك.",
		"audio": "الصوت",
		"master_volume": "الصوت الرئيسي",
		"music_volume": "الموسيقى",
		"sfx_volume": "المؤثرات",
		"mute_audio": "كتم كل الأصوات",
		"language": "اللغة",
		"gameplay": "اللعب",
		"difficulty": "الصعوبة",
		"visuals": "العرض",
		"fullscreen": "ملء الشاشة",
		"resolution": "الدقة",
		"reset": "استعادة الافتراضي",
		"back": "رجوع",
		"back_to_menu": "رجوع للقائمة",
		"preview": "معاينة مباشرة",
		"on": "مفعّل",
		"off": "متوقف",
		"app_title": "🥕 مغامرة الأرنب والجزر 🐰",
		"main_subtitle": "اجمع الجزر، تجنب الثعالب، واندفع بعيدًا عن الخطر!",
		"carrot_wallet": "🥕 {count}",
		"open_skin_shop": "السكنات",
		"skin_shop_title": "🥕 متجر سكنات الأرنب",
		"skin_shop_subtitle": "اشترِ أزياء وإكسسوارات للأرنب بالجزر المحفوظ ثم اختر المفضل لديك.",
		"skin_shop_hint": "اجمع الجزر داخل المراحل، افُز، ثم عد لشراء سكنات جديدة.",
		"skin_price": "السعر: {price} 🥕",
		"skin_owned": "مملوك",
		"skin_buy": "شراء",
		"skin_equip": "اختيار",
		"skin_selected": "مختار",
		"skin_not_enough": "لا يوجد جزر كافٍ بعد.",
		"skin_bought_status": "تم شراء واختيار {name}!",
		"skin_equipped_status": "تم اختيار {name}.",
		"skin_white_name": "الأبيض الكلاسيكي",
		"skin_white_desc": "شكل الأرنب الأصلي الشجاع، جاهز دائمًا للجزر.",
		"skin_brown_name": "أرنب الكاكاو",
		"skin_brown_desc": "فراء بني دافئ لمغامرة حديقة لطيفة.",
		"skin_meadow_name": "وشاح المرج",
		"skin_meadow_desc": "زي أرنب مع وشاح ورقي يساعده على الاندماج في الحديقة.",
		"skin_rose_name": "ربطة الورد",
		"skin_rose_desc": "شكل أرنب مع ربطة وردية لطيفة لمغامرات الربيع.",
		"skin_golden_name": "السترة الذهبية",
		"skin_golden_desc": "سترة أرنب ذهبية لامعة لهواة جمع الجزر الحقيقيين.",
		"skin_night_name": "عباءة القمر",
		"skin_night_desc": "عباءة أرنب داكنة مع شارة قمر لجولات الليل الهادئة.",
		"start_game": "▶  ابدأ اللعب",
		"instructions": "📖  التعليمات",
		"level_map": "🗺  خريطة المراحل",
		"quit": "✖  خروج",
		"how_to_play": "📖 طريقة اللعب",
		"instructions_subtitle": "بطاقات سريعة تساعدك على مغامرة آمنة وممتعة.",
		"instructions_controls_title": "تحرّك باحتراف",
		"instructions_controls_body": "استخدم الأسهم أو WASD للتحرك. اضغط Space أو Enter للاندفاع بسرعة عند اقتراب الخطر.",
		"instructions_collect_title": "اجمع الجزر",
		"instructions_collect_body": "الجزرة البرتقالية تعطي 10 نقاط. الجزرة الذهبية تعطي 25 نقطة، فاجمعها أولًا عندما يكون الطريق آمنًا.",
		"instructions_hazards_title": "اعرف المخاطر",
		"instructions_hazards_body": "الثعالب تطاردك. الجحور حفر ترابية داكنة. شجيرات الشوك خضراء وبها أشواك فاتحة. كل إصابة تنقص حياة واحدة.",
		"instructions_goal_title": "افز بالمرحلة",
		"instructions_goal_body": "وصل للنقاط المطلوبة قبل انتهاء الوقت. اجمع جزرًا كافيًا لتفتح منطقة الحديقة التالية.",
		"instructions_lives_title": "احمِ حيواتك",
		"instructions_lives_body": "تبدأ بعدد الحيوات الظاهر أعلى الشاشة. إذا وصلت الحيوات إلى صفر تنتهي المحاولة.",
		"instructions_tip_title": "نصيحة الأرنب الذكي",
		"instructions_tip_body": "خطط طريقك بعيدًا عن المخاطر، استخدم الاندفاع عند الحاجة فقط، واجمع الجزر الذهبي عندما يكون المسار واضحًا.",
		"instructions_body": "[b]🎮 التحكم:[/b]\n  الأسهم أو WASD — حرّك الأرنب\n  Space أو Enter — اندفاع سريع\n\n[b]🥕 التجميع:[/b]\n  الجزرة البرتقالية = 10 نقاط\n  الجزرة الذهبية = 25 نقطة\n\n[b]⚠ المخاطر:[/b]\n  🦊 الثعالب — تطارد الأرنب وتنقص حياة واحدة.\n  🕳 جحور/حفر الأرض — حفرة بيضاوية داكنة حولها تراب؛ لا تدخل فيها.\n  🌿 شجيرات الشوك — شجيرات خضراء عليها أشواك فاتحة؛ لمسها ينقص حياة واحدة.\n\n[b]🎯 الهدف:[/b]\n  اجمع نقاطًا كافية قبل انتهاء الوقت!\n  وصل للنقاط المطلوبة كي تفوز بالمرحلة.\n\n[b]❤ الحيوات:[/b]\n  تبدأ بثلاث حيوات. كل إصابة تنقص حياة.\n  إذا وصلت الحيوات إلى صفر تنتهي اللعبة!",
		"choose_bunny": "اختر أرنبك! 🐰",
		"white_bunny": "الأرنب الأبيض 🐰",
		"brown_bunny": "الأرنب البني 🐰",
		"white_bunny_button": "⬜ الأرنب الأبيض",
		"brown_bunny_button": "🟫 الأرنب البني",
		"confirm_play": "✔ هيا نلعب!",
		"map_title": "🗺 خريطة مغامرة الحديقة",
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
		"pause_subtitle": "خذ نفسًا — أرنبك بأمان حتى تستأنف اللعب.",
		"pause_resume": "▶ استئناف",
		"pause_restart": "🔄 إعادة المرحلة",
		"pause_lobby": "🏠 العودة للوبي",
		"pause_quit": "✖ الخروج من اللعبة",
		"win_banner": "🎉 فزت! 🎉",
		"final_score": "النقاط النهائية: {score} 🥕",
		"carrots_banked": "الجزر المحفوظ: +{count} 🥕",
		"next_level": "➡ المرحلة التالية",
		"play_again": "🔄 العب مجددًا",
		"main_menu": "🏠 القائمة الرئيسية",
		"all_levels_complete": "🎉 أنهيت كل المراحل!",
		"win_message_1": "عمل رائع! 🌟",
		"win_message_2": "أنت بطل الجزر! 🥕",
		"win_message_3": "أرنب ذكي! 🐰",
		"win_message_4": "مذهل، لا يمكن إيقافك! ⭐",
		"win_message_5": "قفزة ممتازة! استمر! 🎉",
		"game_over_banner": "😢 انتهت اللعبة!",
		"game_over_score": "حصلت على: {score} نقطة",
		"try_again": "🔄 حاول مرة أخرى!",
		"game_over_message_1": "لا تستسلم أيها الأرنب الصغير! 🐰",
		"game_over_message_2": "كنت قريبًا! حاول مرة أخرى! 💪",
		"game_over_message_3": "الجزر ينتظرك! 🥕",
		"game_over_message_4": "تستطيع فعلها! قفزة أخرى! 🌟",
		"result_title": "نتائج المرحلة! 🥕",
		"your_score": "نقاطك: {score}",
		"time_used": "الوقت المستخدم: {time}ث",
		"retry": "🔄 إعادة المحاولة",
		"easy": "سهل",
		"normal": "عادي",
		"hard": "صعب"
	}
	if language == "العربية":
		return str(arabic.get(key, english.get(key, key)))
	return str(english.get(key, key))

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
