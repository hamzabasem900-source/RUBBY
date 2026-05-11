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
@export var arrival_distance: float = 28.0
@export var move_right_first: bool  = true

var start_pos: Vector2 = Vector2.ZERO
var dir:       float   = 1.0
var _player:   Node2D  = null
var _base_scale: Vector2 = Vector2.ONE
var _facing_left: bool = false
var _visual_rects: Array = []
var _visual_offsets: Dictionary = {}

@onready var hurt_area: Area2D = $HurtArea

func _ready() -> void:
	start_pos = global_position
	_base_scale = Vector2(abs(scale.x), abs(scale.y))
	scale = _base_scale
	dir = 1.0 if move_right_first else -1.0
	_cache_visual_offsets()
	_apply_facing(move_right_first == false)
	if hurt_area:
		hurt_area.body_entered.connect(_on_hurt_area_body_entered)

func _physics_process(delta: float) -> void:
	# ── Cache player reference ───────────────────────────────────────────────
	if not _player or not is_instance_valid(_player):
		var group: Array = get_tree().get_nodes_in_group("player")
		_player = group[0] if group.size() > 0 else null

	# ── World search / chase mode ────────────────────────────────────────────
	# Always move toward the bunny when it exists instead of rapidly flipping
	# between short left/right patrol turns at the edge of a patrol range.
	if _player and is_instance_valid(_player):
		var to_player: Vector2 = _player.global_position - global_position
		var dist: float = to_player.length()
		var desired_velocity := Vector2.ZERO
		if dist > arrival_distance:
			var chase_dir: Vector2 = to_player / dist
			desired_velocity = chase_dir * chase_speed
			if abs(chase_dir.x) > 0.08:
				_apply_facing(chase_dir.x < 0.0)
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
		move_and_slide()
		return

	# ── Fallback patrol only if the player is not available ──────────────────
	velocity = velocity.move_toward(Vector2(dir * patrol_speed, 0.0), acceleration * delta)
	if abs(velocity.x) > 1.0:
		_apply_facing(velocity.x < 0.0)
	move_and_slide()

	var offset: float = global_position.x - start_pos.x
	if offset > patrol_distance and dir > 0.0:
		dir = -1.0
	elif offset < -patrol_distance and dir < 0.0:
		dir = 1.0

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

func _apply_facing(face_left: bool) -> void:
	# Keep the physics root scale positive, and mirror only the decorative
	# ColorRects. Negative CharacterBody2D scale causes odd movement/collisions.
	scale = _base_scale
	if _facing_left == face_left:
		return
	_facing_left = face_left
	for rect in _visual_rects:
		var offsets: Array = _visual_offsets[rect]
		if face_left:
			rect.offset_left = -float(offsets[1])
			rect.offset_right = -float(offsets[0])
		else:
			rect.offset_left = float(offsets[0])
			rect.offset_right = float(offsets[1])
		rect.offset_top = float(offsets[2])
		rect.offset_bottom = float(offsets[3])

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
