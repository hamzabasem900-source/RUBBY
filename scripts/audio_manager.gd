extends Node

# يدير كل الاصوات والموسيقى من مكان واحد حتى تستخدمها باقي المشاهد بسهولة

# متغيرات تحفظ حالة هذا السكربت اثناء اللعب
var _players: Dictionary = {}

# قيم ثابتة يستخدمها هذا السكربت اثناء التشغيل
const AUDIO_PATHS: Dictionary = {
	"menu_music":     "res://assets/votes/main_menu_music.mp3",
	"gameplay_music": "res://assets/votes/gameplay_music.mp3",
	"collect_carrot": "res://assets/votes/carrot_collect.mp3",
	"golden_collect": "res://assets/votes/carrot_collect.mp3",
	"damage":         "res://assets/votes/lose_life.wav",
	"button_click":   "res://assets/votes/button_click.mp3",
	"win":            "res://assets/votes/win.mp3",
	"game_over":      "res://assets/votes/game_over.mp3"
}

const MUSIC_KEYS: Array[String] = ["menu_music", "gameplay_music"]

# يبدأ تجهيز هذا المشهد عند دخوله الى شجرة اللعبة
func _ready() -> void:
	_ensure_audio_bus("Music")
	_ensure_audio_bus("SFX")
	for key in AUDIO_PATHS.keys():
		var player := AudioStreamPlayer.new()
		player.name = key
		player.bus = "Music" if MUSIC_KEYS.has(key) else "SFX"
		player.volume_db = _get_volume_for(key)
		add_child(player)
		_players[key] = player
		_load_stream(key, player)
	if get_node_or_null("/root/SettingsManager") != null:
		SettingsManager.apply_audio_settings()

# يحمل ملف الصوت ويربطه بالمشغل المناسب اذا كان موجودا
func _load_stream(sound_name: String, player: AudioStreamPlayer) -> void:
	var path: String = AUDIO_PATHS[sound_name]
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: missing audio file — " + path)
		return
	var stream = load(path)
	if stream is AudioStream:
		player.stream = stream
		_set_stream_loop(player.stream, MUSIC_KEYS.has(sound_name))
	else:
		push_warning("AudioManager: file is not an AudioStream — " + path)

# يرجع مستوى الصوت الابتدائي المناسب لكل مؤثر
func _get_volume_for(sound_name: String) -> float:
	match sound_name:
		"menu_music", "gameplay_music":
			return -12.0
		"button_click":
			return -4.0
		"collect_carrot", "golden_collect":
			return -2.5
		"damage", "game_over":
			return -1.5
		"win":
			return -2.0
		_:
			return 0.0

# يتاكد من وجود قناة صوت مطلوبة قبل استخدامها
func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(idx, bus_name)

# يحدد هل يعاد تشغيل الصوت تلقائيا عند نهايته
func _set_stream_loop(stream: AudioStream, loop: bool) -> void:

	if "loop" in stream:
		stream.loop = loop

# يشغل مؤثرا او موسيقى بالاسم المطلوب
func play(sound_name: String, loop: bool = false) -> void:
	if not _players.has(sound_name):
		return
	var p: AudioStreamPlayer = _players[sound_name]
	if p.stream == null:
		return
	var should_loop := loop or MUSIC_KEYS.has(sound_name)
	_set_stream_loop(p.stream, should_loop)
	if should_loop and p.playing:
		return
	p.play()

# يوقف صوتا واحدا بالاسم المطلوب
func stop(sound_name: String) -> void:
	if _players.has(sound_name):
		_players[sound_name].stop()

# يوقف كل الاصوات والموسيقى الحالية
func stop_all() -> void:
	for p in _players.values():
		p.stop()

# يوقف كل موسيقى الخلفية فقط
func stop_music() -> void:
	for key in MUSIC_KEYS:
		stop(key)

# يوقف مؤثرات شاشات النهاية عند الحاجة
func stop_end_screen_sfx() -> void:
	stop("game_over")
	stop("win")

# يشغل موسيقى القائمة الرئيسية
func play_menu_music() -> void:
	play_music("menu_music")

# يشغل موسيقى اللعب
func play_gameplay_music() -> void:
	play_music("gameplay_music")

# يشغل موسيقى واحدة ويوقف باقي الموسيقى
func play_music(sound_name: String) -> void:
	if not MUSIC_KEYS.has(sound_name):
		return
	if _is_music_already_playing(sound_name):
		return
	for key in MUSIC_KEYS:
		if key != sound_name:
			stop(key)
	play(sound_name, true)

# يفحص هل الموسيقى المطلوبة تعمل حاليا
func _is_music_already_playing(sound_name: String) -> bool:
	if not _players.has(sound_name):
		return false
	var player: AudioStreamPlayer = _players[sound_name]
	return player.playing

# يشغل صوت جمع الجزرة العادية
func play_collect() -> void:
	play("collect_carrot")

# يشغل صوت جمع الجزرة الذهبية
func play_golden_collect() -> void:
	play("golden_collect")

# يشغل صوت تلقي الضرر
func play_damage() -> void:
	play("damage")

# يشغل صوت الضغط على الازرار
func play_button_click() -> void:
	play("button_click")

# يشغل صوت الفوز بعد ايقاف باقي الاصوات
func play_win() -> void:
	stop_all()
	play("win")

# يشغل صوت الخسارة بعد ايقاف باقي الاصوات
func play_game_over() -> void:
	stop_all()
	play("game_over")
