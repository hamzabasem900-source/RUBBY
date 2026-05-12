extends Area2D

# =============================================
# Static Hazard — Burrow Hole or Thorn Bush
# =============================================

@export var is_hole: bool = false:
	set(value):
		is_hole = value
		if is_node_ready():
			_apply_style()

func _ready() -> void:
	add_to_group("hazard")
	body_entered.connect(_on_body_entered)
	_apply_style()

func _apply_style() -> void:
	var shadow := get_node_or_null("Shadow") as CanvasItem
	if shadow != null:
		shadow.visible = true

	var hole_nodes := ["DirtRim", "InnerPit", "Highlight", "Pebble1", "Pebble2"]
	var thorn_nodes := ["BackLeaves", "FrontLeaves", "LeafHighlight", "WarningRing", "ThornTop", "ThornRight", "ThornLeft", "ThornBottom", "ThornCenter", "ThornUpperLeft", "ThornUpperRight", "ThornLowerLeft", "ThornLowerRight"]
	for node_name in hole_nodes:
		var node := get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.visible = is_hole
	for node_name in thorn_nodes:
		var node := get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.visible = not is_hole

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
