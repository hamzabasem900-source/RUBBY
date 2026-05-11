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
		"start_game": "▶  Start Game",
		"instructions": "📖  Instructions",
		"level_map": "🗺  Level Map",
		"quit": "✖  Quit",
		"how_to_play": "📖 How To Play",
		"instructions_body": "[b]🎮 Controls:[/b]\n  Arrow Keys or WASD — Move your bunny\n  Space or Enter — Quick dash burst\n\n[b]🥕 Collect:[/b]\n  Orange Carrot = 10 points\n  Golden Carrot = 25 points\n\n[b]⚠ Avoid:[/b]\n  🦊 Foxes — they chase and hurt you!\n  ⚫ Holes — don't fall in!\n  🌵 Thorn Bushes — ouch!\n\n[b]🎯 Goal:[/b]\n  Collect enough points before the timer ends!\n  Reach the required score to win the level.\n\n[b]❤ Lives:[/b]\n  You start with 3 lives. Each hit = -1 life.\n  If lives reach 0, it's Game Over!",
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
		"win_banner": "🎉 YOU WIN! 🎉",
		"final_score": "Final Score: {score} 🥕",
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
		"start_game": "▶  ابدأ اللعب",
		"instructions": "📖  التعليمات",
		"level_map": "🗺  خريطة المراحل",
		"quit": "✖  خروج",
		"how_to_play": "📖 طريقة اللعب",
		"instructions_body": "[b]🎮 التحكم:[/b]\n  الأسهم أو WASD — حرّك الأرنب\n  Space أو Enter — اندفاع سريع\n\n[b]🥕 التجميع:[/b]\n  الجزرة البرتقالية = 10 نقاط\n  الجزرة الذهبية = 25 نقطة\n\n[b]⚠ تجنّب:[/b]\n  🦊 الثعالب — تطاردك وتؤذيك!\n  ⚫ الحفر — لا تقع فيها!\n  🌵 الشوك — مؤلم!\n\n[b]🎯 الهدف:[/b]\n  اجمع نقاطًا كافية قبل انتهاء الوقت!\n  وصل للنقاط المطلوبة كي تفوز بالمرحلة.\n\n[b]❤ الحيوات:[/b]\n  تبدأ بثلاث حيوات. كل إصابة تنقص حياة.\n  إذا وصلت الحيوات إلى صفر تنتهي اللعبة!",
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
		"win_banner": "🎉 فزت! 🎉",
		"final_score": "النقاط النهائية: {score} 🥕",
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
