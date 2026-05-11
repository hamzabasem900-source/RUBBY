extends CharacterBody2D

# =============================================
# Fox Enemy — Patrol + Chase AI
# The fox patrols a fixed range but switches to
# chasing the player when it gets close enough.
# =============================================

@export var patrol_distance:  float = 100.0
@export var patrol_speed:     float = 88.0
@export var chase_speed:      float = 145.0
@export var chase_range:      float = 180.0
@export var move_right_first: bool  = true

var start_pos: Vector2 = Vector2.ZERO
var dir:       float   = 1.0
var _player:   Node2D  = null

@onready var hurt_area: Area2D = $HurtArea

func _ready() -> void:
	start_pos = global_position
	dir       = 1.0 if move_right_first else -1.0
	if hurt_area:
		hurt_area.body_entered.connect(_on_hurt_area_body_entered)

func _physics_process(_delta: float) -> void:
	# ── Cache player reference ───────────────────────────────────────────────
	if not _player or not is_instance_valid(_player):
		var group: Array = get_tree().get_nodes_in_group("player")
		_player = group[0] if group.size() > 0 else null

	# ── Chase mode ───────────────────────────────────────────────────────────
	if _player and is_instance_valid(_player):
		var dist: float = global_position.distance_to(_player.global_position)
		if dist < chase_range:
			var chase_dir: Vector2 = \
				(_player.global_position - global_position).normalized()
			velocity = chase_dir * chase_speed
			scale.x  = -1.0 if chase_dir.x < 0.0 else 1.0
			move_and_slide()
			return

	# ── Patrol mode ──────────────────────────────────────────────────────────
	velocity = Vector2(dir * patrol_speed, 0.0)
	scale.x  = -1.0 if dir < 0.0 else 1.0
	move_and_slide()

	var offset: float = global_position.x - start_pos.x
	if offset > patrol_distance and dir > 0.0:
		dir = -1.0
	elif offset < -patrol_distance and dir < 0.0:
		dir = 1.0

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
