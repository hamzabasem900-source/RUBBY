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

@onready var hurt_area: Area2D = $HurtArea

func _ready() -> void:
	start_pos = global_position
	_base_scale = Vector2(abs(scale.x), abs(scale.y))
	scale = _base_scale
	dir       = 1.0 if move_right_first else -1.0
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
				_apply_facing()
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
		move_and_slide()
		return

	# ── Fallback patrol only if the player is not available ──────────────────
	velocity = velocity.move_toward(Vector2(dir * patrol_speed, 0.0), acceleration * delta)
	if abs(velocity.x) > 1.0:
		_apply_facing()
	move_and_slide()

	var offset: float = global_position.x - start_pos.x
	if offset > patrol_distance and dir > 0.0:
		dir = -1.0
	elif offset < -patrol_distance and dir < 0.0:
		dir = 1.0

func _apply_facing() -> void:
	# Do not use negative scale for left-facing movement: mirrored physics
	# bodies and emoji/label sprites can look distorted and move oddly.
	scale = _base_scale

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
