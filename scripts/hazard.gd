extends Area2D

# يعرف العوائق الثابتة مثل الحفرة والشوك حتى تضر اللاعب عند لمسها

# قيم قابلة للتعديل من داخل المحرر لضبط سلوك المشهد
@export var is_hole: bool = false:
	set(value):
		is_hole = value
		if is_node_ready():
			_apply_style()

# يبدأ تجهيز هذا المشهد عند دخوله الى شجرة اللعبة
func _ready() -> void:
	add_to_group("hazard")
	body_entered.connect(_on_body_entered)
	_apply_style()

# يطبق الوان الجزرة ولمعتها حسب نوعها
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

# يشرح هذا الجزء وظيفة مساعدة داخل السكربت
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
