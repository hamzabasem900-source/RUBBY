extends Node

# =============================================
# SettingsManager — AutoLoad Singleton
# Saves player preferences and applies global presentation settings.
# =============================================

signal settings_changed
signal language_changed(language: String)

const CONFIG_PATH: String = "user://settings.cfg"
const SECTION: String = "game"

const DEFAULT_SETTINGS: Dictionary = {
	"master_volume": 0.85,
	"music_volume": 0.70,
	"sfx_volume": 0.85,
	"mute_audio": false,
	"language": "English",
	"fullscreen": false,
	"resolution": "1024 x 720",
	"show_fps": false,
	"reduce_motion": false,
	"show_tips": true,
	"difficulty": "Normal",
	"camera_shake": true,
	"touch_controls": false,
	"color_assist": false
}

var values: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var _fps_label: Label

func _ready() -> void:
	load_settings()
	apply_all()

func _process(_delta: float) -> void:
	_update_fps_overlay()

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
	apply_fps_overlay()

func apply_window_settings() -> void:
	var fullscreen: bool = bool(values["fullscreen"])
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if not fullscreen:
		var size := _resolution_to_vector(str(values["resolution"]))
		DisplayServer.window_set_size(size)
		var screen_size := DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size - size) / 2)

func apply_audio_settings() -> void:
	_set_bus_volume("Master", float(values["master_volume"]), bool(values["mute_audio"]))
	_set_bus_volume("Music", float(values["music_volume"]), bool(values["mute_audio"]))
	_set_bus_volume("SFX", float(values["sfx_volume"]), bool(values["mute_audio"]))

func apply_fps_overlay() -> void:
	if not bool(values["show_fps"]):
		if _fps_label != null:
			_fps_label.queue_free()
			_fps_label = null
		return
	if _fps_label != null:
		return
	_fps_label = Label.new()
	_fps_label.name = "FpsOverlay"
	_fps_label.top_level = true
	_fps_label.position = Vector2(14, 12)
	_fps_label.add_theme_font_size_override("font_size", 18)
	_fps_label.add_theme_color_override("font_color", Color(1, 1, 0.55, 1))
	add_child(_fps_label)

func _update_fps_overlay() -> void:
	if _fps_label != null:
		_fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

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
		"1280 x 720":
			return Vector2i(1280, 720)
		"1600 x 900":
			return Vector2i(1600, 900)
		"1920 x 1080":
			return Vector2i(1920, 1080)
		_:
			return Vector2i(1024, 720)

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
		"show_tips": "Show helpful tips",
		"touch_controls": "Touch controls",
		"camera_shake": "Camera shake",
		"visuals": "Visuals",
		"fullscreen": "Fullscreen",
		"resolution": "Resolution",
		"show_fps": "Show FPS",
		"reduce_motion": "Reduce motion",
		"color_assist": "High contrast colors",
		"reset": "Reset Defaults",
		"back": "Back to Menu",
		"preview": "Live Preview"
	}
	var arabic := {
		"settings": "الإعدادات",
		"settings_subtitle": "اضبط مغامرتك بالطريقة التي تناسبك.",
		"audio": "الصوت",
		"master_volume": "الصوت الرئيسي",
		"music_volume": "الموسيقى",
		"sfx_volume": "المؤثرات",
		"mute_audio": "كتم كل الأصوات",
		"language": "اللغة",
		"gameplay": "اللعب",
		"difficulty": "الصعوبة",
		"show_tips": "إظهار التلميحات",
		"touch_controls": "أزرار اللمس",
		"camera_shake": "اهتزاز الكاميرا",
		"visuals": "العرض",
		"fullscreen": "ملء الشاشة",
		"resolution": "الدقة",
		"show_fps": "إظهار FPS",
		"reduce_motion": "تقليل الحركة",
		"color_assist": "ألوان عالية التباين",
		"reset": "استعادة الافتراضي",
		"back": "رجوع للقائمة",
		"preview": "معاينة مباشرة"
	}
	if language == "العربية":
		return str(arabic.get(key, english.get(key, key)))
	return str(english.get(key, key))
