extends Node2D

# =============================================
# GameLevel — Main Gameplay Controller
# Spawns objects, handles win/gameover transitions
# =============================================

const SCENE_WIN:      String = "res://scenes/WinScreen.tscn"
const SCENE_GAMEOVER: String = "res://scenes/GameOver.tscn"

const CARROT_SCENE: String = "res://scenes/Carrot.tscn"
const FOX_SCENE:    String = "res://scenes/Fox.tscn"
const HOLE_SCENE:   String = "res://scenes/Hole.tscn"
const THORN_SCENE:  String = "res://scenes/Thorn.tscn"

# Safe play area (inside border walls)
const AREA_MIN := Vector2(96.0,  105.0)
const AREA_MAX := Vector2(928.0, 640.0)

var transitioning: bool = false

func _ready() -> void:
	GameManager.level_won.connect(_on_level_won)
	GameManager.game_over.connect(_on_game_over)
	GameManager.timer_running = true
	AudioManager.play_gameplay_music()
	_spawn_all()

func _process(delta: float) -> void:
	if not transitioning:
		GameManager.tick_timer(delta)

# ── Spawning ─────────────────────────────────────────────────────────────────

func _spawn_all() -> void:
	var config: Dictionary = GameManager.get_level_config(GameManager.current_level)
	var used: Array = []

	# Keep centre clear for player start
	used.append(Vector2(512, 380))

	for _i in range(config["carrot_count"]):
		_spawn(CARROT_SCENE, used, false)

	for _i in range(config["golden_carrot_count"]):
		_spawn(CARROT_SCENE, used, true)

	for _i in range(config["hole_count"]):
		_spawn_hazard(HOLE_SCENE, used, true)

	for _i in range(config["thorn_count"]):
		_spawn_hazard(THORN_SCENE, used, false)

	for _i in range(config["fox_count"]):
		_spawn_fox(used)

func _random_pos(used: Array, min_dist: float = 55.0) -> Vector2:
	var pos := Vector2.ZERO
	for _attempt in range(80):
		pos = Vector2(
			randf_range(AREA_MIN.x, AREA_MAX.x),
			randf_range(AREA_MIN.y, AREA_MAX.y)
		)
		var ok := true
		for u in used:
			if pos.distance_to(u) < min_dist:
				ok = false
				break
		if ok:
			break
	used.append(pos)
	return pos

func _spawn(scene_path: String, used: Array, golden: bool) -> void:
	if not ResourceLoader.exists(scene_path):
		push_warning("GameLevel: scene not found — " + scene_path)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_warning("GameLevel: failed to load — " + scene_path)
		return
	var obj := packed.instantiate()
	add_child(obj)
	obj.scale = Vector2(1.2, 1.2)
	obj.global_position = _random_pos(used)
	# Property setter handles the colour update
	if "is_golden" in obj:
		obj.is_golden = golden

func _spawn_hazard(scene_path: String, used: Array, is_hole: bool) -> void:
	if not ResourceLoader.exists(scene_path):
		push_warning("GameLevel: scene not found — " + scene_path)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_warning("GameLevel: failed to load — " + scene_path)
		return
	var obj := packed.instantiate()
	add_child(obj)
	obj.scale = Vector2(1.18, 1.18)
	obj.global_position = _random_pos(used, 60.0)
	# Property setter handles the colour update
	if "is_hole" in obj:
		obj.is_hole = is_hole

func _spawn_fox(used: Array) -> void:
	if not ResourceLoader.exists(FOX_SCENE):
		push_warning("GameLevel: Fox scene not found")
		return
	var packed := load(FOX_SCENE) as PackedScene
	if packed == null:
		return
	var fox := packed.instantiate()
	add_child(fox)
	fox.scale = Vector2(1.08, 1.08)
	fox.global_position = _random_pos(used, 100.0)
	if "patrol_distance" in fox:
		fox.patrol_distance = randf_range(100.0, 190.0)
	if "move_right_first" in fox:
		fox.move_right_first = (randi() % 2 == 0)

# ── Transitions ───────────────────────────────────────────────────────────────

func _on_level_won() -> void:
	if transitioning:
		return
	transitioning = true
	GameManager.timer_running = false
	GameManager.unlock_next_level()
	AudioManager.play_win()
	await get_tree().create_timer(0.9).timeout
	get_tree().change_scene_to_file(SCENE_WIN)

func _on_game_over() -> void:
	if transitioning:
		return
	transitioning = true
	GameManager.timer_running = false
	AudioManager.play_game_over()
	await get_tree().create_timer(0.9).timeout
	get_tree().change_scene_to_file(SCENE_GAMEOVER)
