extends Node

# =============================================
# AudioManager — AutoLoad Singleton
# Safe: game won't crash if audio files missing
# Place .ogg files in res://assets/audio/
# =============================================

var _players: Dictionary = {}

const AUDIO_PATHS: Dictionary = {
	"menu_music":     "res://assets/audio/menu_music.ogg",
	"gameplay_music": "res://assets/audio/gameplay_music.ogg",
	"collect_carrot": "res://assets/audio/collect_carrot.ogg",
	"golden_collect": "res://assets/audio/golden_collect.ogg",
	"damage":         "res://assets/audio/damage.ogg",
	"button_click":   "res://assets/audio/button_click.ogg",
	"win":            "res://assets/audio/win.ogg",
	"game_over":      "res://assets/audio/game_over.ogg"
}

func _ready() -> void:
	for key in AUDIO_PATHS.keys():
		var player := AudioStreamPlayer.new()
		player.name = key
		add_child(player)
		_players[key] = player
		if ResourceLoader.exists(AUDIO_PATHS[key]):
			var stream = load(AUDIO_PATHS[key])
			if stream is AudioStream:
				player.stream = stream

func play(sound_name: String, loop: bool = false) -> void:
	if not _players.has(sound_name):
		return
	var p: AudioStreamPlayer = _players[sound_name]
	if p.stream == null:
		return
	if loop and p.stream is AudioStreamOggVorbis:
		p.stream.loop = true
	p.play()

func stop(sound_name: String) -> void:
	if _players.has(sound_name):
		_players[sound_name].stop()

func stop_all() -> void:
	for p in _players.values():
		p.stop()

func play_menu_music() -> void:
	stop_all()
	play("menu_music", true)

func play_gameplay_music() -> void:
	stop_all()
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
