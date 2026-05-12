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
var _visual_rects: Array = []
var _visual_offsets: Dictionary = {}
var _attack_pause_timer: float = 0.0
var _damage_cooldown_timer: float = 0.0
var _walk_time: float = 0.0

@onready var hurt_area: Area2D = $HurtArea

func _ready() -> void:
	add_to_group("fox")
	start_pos = global_position
	_base_scale = Vector2(abs(scale.x), abs(scale.y))
	scale = _base_scale
	dir = 1.0 if move_right_first else -1.0
	_cache_visual_offsets()
	_apply_facing(move_right_first == false)
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
		if abs(velocity.x) > 1.0:
			_apply_facing(velocity.x < 0.0)
		move_and_slide()
		_animate_fox(delta)
		return

	# ── Fallback patrol only if the player is not available ──────────────────
	velocity = velocity.move_toward(Vector2(dir * patrol_speed, 0.0), acceleration * delta)
	if abs(velocity.x) > 1.0:
		_apply_facing(velocity.x < 0.0)
	move_and_slide()
	_animate_fox(delta)

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
		"EarRight", "InnerEarLeft", "InnerEarRight", "Snout", "Cheek",
		"Eye", "EyeGlint", "Nose", "WhiskerTop", "WhiskerBottom",
		"LegFront", "LegBack", "PawFront", "PawBack"
	]
	for node_name in visual_names:
		var rect := get_node_or_null(node_name) as ColorRect
		if rect:
			_visual_rects.append(rect)
			_visual_offsets[rect] = [
				rect.offset_left, rect.offset_right,
				rect.offset_top, rect.offset_bottom
			]

func _apply_facing(face_left: bool) -> void:
	# Keep the physics root scale positive, and mirror only the decorative
	# ColorRects. Negative CharacterBody2D scale causes odd movement/collisions.
	scale = _base_scale
	if _facing_left == face_left:
		return
	_facing_left = face_left
	for rect in _visual_rects:
		_position_visual_rect(rect, 0.0, 0.0)

func _animate_fox(delta: float) -> void:
	var speed_ratio: float = clamp(velocity.length() / max(chase_speed, 1.0), 0.0, 1.0)
	if speed_ratio <= 0.03:
		_walk_time = 0.0
	else:
		_walk_time += delta * lerp(6.0, 13.0, speed_ratio)
	var body_bob: float = sin(_walk_time * 2.0) * 1.6 * speed_ratio
	var leg_stride: float = sin(_walk_time) * 5.0 * speed_ratio
	var tail_sway: float = sin(_walk_time * 1.35) * 2.4 * speed_ratio
	for rect in _visual_rects:
		var y_shift := 0.0
		var x_shift := 0.0
		match rect.name:
			"Sprite", "Chest", "Head", "EarLeft", "EarRight", "InnerEarLeft", "InnerEarRight", "Snout", "Cheek", "Eye", "EyeGlint", "Nose", "WhiskerTop", "WhiskerBottom":
				y_shift = body_bob
			"LegFront", "PawFront":
				x_shift = leg_stride
				y_shift = abs(leg_stride) * -0.18
			"LegBack", "PawBack":
				x_shift = -leg_stride
				y_shift = abs(leg_stride) * -0.18
			"Tail", "TailTip":
				y_shift = body_bob - tail_sway
		_position_visual_rect(rect, x_shift, y_shift)

func _position_visual_rect(rect: ColorRect, x_shift: float, y_shift: float) -> void:
	var offsets: Array = _visual_offsets[rect]
	var signed_x_shift := -x_shift if _facing_left else x_shift
	if _facing_left:
		rect.offset_left = -float(offsets[1]) + signed_x_shift
		rect.offset_right = -float(offsets[0]) + signed_x_shift
	else:
		rect.offset_left = float(offsets[0]) + signed_x_shift
		rect.offset_right = float(offsets[1]) + signed_x_shift
	rect.offset_top = float(offsets[2]) + y_shift
	rect.offset_bottom = float(offsets[3]) + y_shift

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if _damage_cooldown_timer > 0.0:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
		_damage_cooldown_timer = damage_cooldown
		_attack_pause_timer = attack_pause_duration
		var away: Vector2 = global_position - body.global_position
		velocity = (away.normalized() if away.length() > 0.001 else Vector2.RIGHT) * attack_recoil_speed
