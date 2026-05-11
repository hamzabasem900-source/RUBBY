extends Area2D

# =============================================
# Static Hazard — Hole or Thorn Bush
# Bug fix: is_hole now uses a setter so the colour updates
# even when the property is assigned after _ready() runs.
# =============================================

@export var is_hole: bool = false:
	set(value):
		is_hole = value
		if is_node_ready():
			_apply_style()

@onready var sprite: ColorRect = $Sprite

func _ready() -> void:
	add_to_group("hazard")
	body_entered.connect(_on_body_entered)
	_apply_style()

func _apply_style() -> void:
	if not sprite:
		return
	sprite.color = Color(0.08, 0.04, 0.0) if is_hole else Color(0.12, 0.45, 0.08)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
