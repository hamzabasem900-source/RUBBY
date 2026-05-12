extends CharacterBody2D

# =============================================
# Fox Enemy — Patrol + Chase AI
# The fox patrols a fixed range but switches to
# searching for and chasing the player across the whole world.
# =============================================

@export var patrol_distance:  float = 100.0
@export var patrol_speed:     float = 62.0
@export var chase_speed:      float = 132.0
@export var chase_range:      float = 9999.0
@export var acceleration:     float = 520.0
@export var arrival_distance: float = 52.0
@export var separation_distance: float = 72.0
@export var separation_strength: float = 150.0
@export var attack_recoil_speed: float = 210.0
@export var attack_pause_duration: float = 0.45
@export var damage_cooldown: float = 0.9
@export var move_right_first: bool  = true

var start_pos: Vector2 = Vector2.ZERO
var dir:       float   = 1.0
var _player:   Node2D  = null
var _base_scale: Vector2 = Vector2.ONE
var _facing_left: bool = false
var _direction_key: String = "right"
var _visual_rects: Array = []
var _visual_offsets: Dictionary = {}
var _attack_pause_timer: float = 0.0
var _damage_cooldown_timer: float = 0.0

@onready var hurt_area: Area2D = $HurtArea

func _ready() -> void:
	add_to_group("fox")
	start_pos = global_position
	_base_scale = Vector2(abs(scale.x), abs(scale.y))
	scale = _base_scale
	dir = 1.0 if move_right_first else -1.0
	_cache_visual_offsets()
	_apply_direction(Vector2(dir, 0.0))
	if hurt_area:
		hurt_area.body_entered.connect(_on_hurt_area_body_entered)

func _physics_process(delta: float) -> void:
	_attack_pause_timer = max(_attack_pause_timer - delta, 0.0)
	_damage_cooldown_timer = max(_damage_cooldown_timer - delta, 0.0)

	# ── Cache player reference ───────────────────────────────────────────────
	if not _player or not is_instance_valid(_player):
		var group: Array = get_tree().get_nodes_in_group("player")
		_player = group[0] if group.size() > 0 else null

	# ── World search / chase mode ────────────────────────────────────────────
	# Chase the bunny, but keep a personal-space ring so foxes do not stack
	# on top of the player and trap the physics body.
	if _player and is_instance_valid(_player):
		var desired_velocity: Vector2 = _get_chase_velocity()
		desired_velocity += _get_fox_separation_velocity()
		if desired_velocity.length() > chase_speed:
			desired_velocity = desired_velocity.normalized() * chase_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
		if velocity.length() > 1.0:
			_apply_direction(velocity)
		move_and_slide()
		return

	# ── Fallback patrol only if the player is not available ──────────────────
	velocity = velocity.move_toward(Vector2(dir * patrol_speed, 0.0), acceleration * delta)
	if velocity.length() > 1.0:
		_apply_direction(velocity)
	move_and_slide()

	var offset: float = global_position.x - start_pos.x
	if offset > patrol_distance and dir > 0.0:
		dir = -1.0
	elif offset < -patrol_distance and dir < 0.0:
		dir = 1.0

func _get_chase_velocity() -> Vector2:
	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()
	if dist <= 0.001:
		return Vector2.ZERO
	var away_from_player: Vector2 = -to_player / dist
	if _attack_pause_timer > 0.0:
		return away_from_player * attack_recoil_speed
	if dist < arrival_distance:
		var push_ratio: float = 1.0 - (dist / arrival_distance)
		return away_from_player * separation_strength * push_ratio
	var chase_dir: Vector2 = to_player / dist
	return chase_dir * chase_speed

func _get_fox_separation_velocity() -> Vector2:
	var separation := Vector2.ZERO
	for fox in get_tree().get_nodes_in_group("fox"):
		if fox == self or not is_instance_valid(fox) or not (fox is Node2D):
			continue
		var away: Vector2 = global_position - (fox as Node2D).global_position
		var dist: float = away.length()
		if dist > 0.001 and dist < separation_distance:
			var force: float = 1.0 - (dist / separation_distance)
			separation += (away / dist) * separation_strength * force
	return separation

func _cache_visual_offsets() -> void:
	var visual_names := [
		"Tail", "TailTip", "Sprite", "Chest", "Head", "EarLeft",
		"EarRight", "Snout", "Eye", "Nose", "LegFront", "LegBack"
	]
	for node_name in visual_names:
		var rect := get_node_or_null(node_name) as ColorRect
		if rect:
			_visual_rects.append(rect)
			_visual_offsets[rect] = [
				rect.offset_left, rect.offset_right,
				rect.offset_top, rect.offset_bottom
			]

func _apply_direction(move_dir: Vector2) -> void:
	# Keep the physics root scale positive, and adjust only decorative ColorRects.
	# Foxes now visibly react to all 4 movement directions, not only left/right.
	scale = _base_scale
	var new_key := _get_direction_key(move_dir)
	if _direction_key == new_key:
		return
	_direction_key = new_key
	_facing_left = new_key == "left"
	for rect in _visual_rects:
		_apply_rect_direction(rect, _facing_left, new_key)

func _get_direction_key(move_dir: Vector2) -> String:
	if abs(move_dir.x) >= abs(move_dir.y):
		return "left" if move_dir.x < 0.0 else "right"
	return "up" if move_dir.y < 0.0 else "down"

func _apply_rect_direction(rect: ColorRect, face_left: bool, direction_key: String) -> void:
	var offsets: Array = _visual_offsets[rect]
	var left := float(offsets[0])
	var right := float(offsets[1])
	var top := float(offsets[2])
	var bottom := float(offsets[3])
	if face_left:
		left = -float(offsets[1])
		right = -float(offsets[0])
	var vertical_shift := _get_vertical_direction_shift(rect.name, direction_key)
	rect.offset_left = left
	rect.offset_right = right
	rect.offset_top = top + vertical_shift
	rect.offset_bottom = bottom + vertical_shift

func _get_vertical_direction_shift(rect_name: StringName, direction_key: String) -> float:
	var name := str(rect_name)
	if direction_key == "up":
		if name in ["Head", "EarLeft", "EarRight", "Snout", "Eye", "Nose"]:
			return -7.0
		if name in ["Sprite", "Chest", "Tail", "TailTip"]:
			return 3.0
	elif direction_key == "down":
		if name in ["Head", "EarLeft", "EarRight", "Snout", "Eye", "Nose"]:
			return 6.0
		if name in ["LegFront", "LegBack"]:
			return -2.0
	return 0.0

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if _damage_cooldown_timer > 0.0:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
		_damage_cooldown_timer = damage_cooldown
		_attack_pause_timer = attack_pause_duration
		var away: Vector2 = global_position - body.global_position
		velocity = (away.normalized() if away.length() > 0.001 else Vector2.RIGHT) * attack_recoil_speed
