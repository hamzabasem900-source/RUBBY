extends Node

# =============================================
# AudioManager — AutoLoad Singleton
# Safe: game won't crash if audio files missing.
# Put the provided files in res://assets/votes/:
# button_click.mp3, carrot_collect.mp3, gameplay_music.mp3,
# game_over.mp3, lose_life.wav, main_menu_music.mp3, win.mp3
# =============================================

var _players: Dictionary = {}

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

func _ready() -> void:
	for key in AUDIO_PATHS.keys():
		var player := AudioStreamPlayer.new()
		player.name = key
		player.volume_db = _get_volume_for(key)
		add_child(player)
		_players[key] = player
		_load_stream(key, player)

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

func _set_stream_loop(stream: AudioStream, loop: bool) -> void:
	# MP3, WAV, and OGG stream resources expose a loop property in Godot.
	# Guard it so missing/unsupported stream types do not crash the game.
	if "loop" in stream:
		stream.loop = loop

func play(sound_name: String, loop: bool = false) -> void:
	if not _players.has(sound_name):
		return
	var p: AudioStreamPlayer = _players[sound_name]
	if p.stream == null:
		return
	_set_stream_loop(p.stream, loop or MUSIC_KEYS.has(sound_name))
	p.play()

func stop(sound_name: String) -> void:
	if _players.has(sound_name):
		_players[sound_name].stop()

func stop_all() -> void:
	for p in _players.values():
		p.stop()

func stop_music() -> void:
	for key in MUSIC_KEYS:
		stop(key)

func play_menu_music() -> void:
	stop_music()
	play("menu_music", true)

func play_gameplay_music() -> void:
	stop_music()
	play("gameplay_music", true)

func play_collect() -> void:
	play("collect_carrot")

func play_golden_collect() -> void:
	play("golden_collect")

func play_damage() -> void:
	play("damage")

func play_button_click() -> void:
	play("button_click")

func play_win() -> void:
	stop_all()
	play("win")

func play_game_over() -> void:
	stop_all()
	play("game_over")
