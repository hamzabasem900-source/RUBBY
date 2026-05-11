extends Area2D

# =============================================
# Carrot Collectible
# Normal = 10 pts | Golden = 25 pts
# Bug fixes:
#   - is_golden now uses a setter so colour updates even when
#     the property is assigned AFTER _ready() runs.
#   - bob_offset is initialized lazily on the first _process
#     frame so the actual spawned position is captured.
# =============================================

@export var is_golden: bool = false:
	set(value):
		is_golden = value
		if is_node_ready():
			_apply_style()

var collected:     bool  = false
var bob_offset:    float = 0.0
var bob_time:      float = 0.0
var _bob_ready:    bool  = false

@onready var sprite:    ColorRect     = $Sprite
@onready var particles: CPUParticles2D = $CollectParticles

const NORMAL_COLOR := Color(1.0, 0.50, 0.00)
const GOLDEN_COLOR := Color(1.0, 0.85, 0.00)

func _ready() -> void:
	add_to_group("carrot")
	_apply_style()

func _apply_style() -> void:
	if not sprite:
		return
	if is_golden:
		sprite.color    = GOLDEN_COLOR
		sprite.size     = Vector2(22, 28)
		sprite.position = Vector2(-11, -14)
	else:
		sprite.color    = NORMAL_COLOR
		sprite.size     = Vector2(18, 28)
		sprite.position = Vector2(-9, -14)

func _process(delta: float) -> void:
	if collected:
		return
	# Lazy-init so we capture the real spawned Y position
	if not _bob_ready:
		bob_offset = position.y
		_bob_ready = true
	bob_time   += delta
	position.y  = bob_offset + sin(bob_time * 2.8) * 4.0

func get_points() -> int:
	return 25 if is_golden else 10

func get_currency_value() -> int:
	return 1

func collect() -> void:
	if collected:
		return
	collected = true
	set_deferred("monitoring", false)
	if sprite:
		sprite.visible = false
	if particles:
		particles.emitting = true
	await get_tree().create_timer(0.5).timeout
	queue_free()
