extends Area2D

# يجهز الجزرة القابلة للجمع ويحدد شكلها وقيمتها وحركة الطفو الخاصة بها

# اشارات يرسلها هذا السكربت حتى تعرف باقي الاجزاء ان الحالة تغيرت
signal collected_for_respawn(is_golden: bool, world_position: Vector2)

# قيم قابلة للتعديل من داخل المحرر لضبط سلوك المشهد
@export var is_golden: bool = false:
	set(value):
		is_golden = value
		if is_node_ready():
			_apply_style()

# متغيرات تحفظ حالة هذا السكربت اثناء اللعب
var collected:     bool  = false
var bob_offset:    float = 0.0
var bob_time:      float = 0.0
var _bob_ready:    bool  = false

# مراجع جاهزة لعقد المشهد حتى يتم تعديل النصوص والازرار والرسوم بسرعة
@onready var body:       Polygon2D      = $Body
@onready var glow:       Polygon2D      = $Glow
@onready var outline:    Line2D         = $BodyOutline
@onready var highlight:  Line2D         = $Highlight
@onready var particles:  CPUParticles2D = $CollectParticles

# قيم ثابتة يستخدمها هذا السكربت اثناء التشغيل
const NORMAL_COLOR := Color(1.0, 0.50, 0.00)
const NORMAL_DARK := Color(0.62, 0.22, 0.00)
const NORMAL_LIGHT := Color(1.0, 0.86, 0.38)
const GOLDEN_COLOR := Color(1.0, 0.86, 0.06)
const GOLDEN_DARK := Color(0.72, 0.48, 0.00)
const GOLDEN_LIGHT := Color(1.0, 1.0, 0.62)

# يبدأ تجهيز هذا المشهد عند دخوله الى شجرة اللعبة
func _ready() -> void:
	add_to_group("carrot")
	_apply_style()

# يطبق الوان الجزرة ولمعتها حسب نوعها
func _apply_style() -> void:
	var main_color := GOLDEN_COLOR if is_golden else NORMAL_COLOR
	var dark_color := GOLDEN_DARK if is_golden else NORMAL_DARK
	var light_color := GOLDEN_LIGHT if is_golden else NORMAL_LIGHT
	var visual_scale := Vector2(1.16, 1.16) if is_golden else Vector2.ONE

	for node in _visual_nodes():
		if node != null:
			node.scale = visual_scale

	if body != null:
		body.color = main_color
	if glow != null:
		glow.color = Color(main_color.r, main_color.g, main_color.b, 0.34 if is_golden else 0.24)
		glow.scale = visual_scale * (Vector2(1.12, 1.12) if is_golden else Vector2.ONE)
	if outline != null:
		outline.default_color = dark_color
	if highlight != null:
		highlight.default_color = Color(light_color.r, light_color.g, light_color.b, 0.95)
	for stripe_name in ["StripeTop", "StripeMiddle", "StripeBottom"]:
		var stripe := get_node_or_null(stripe_name) as Line2D
		if stripe != null:
			stripe.default_color = Color(dark_color.r, dark_color.g, dark_color.b, 0.72)
	if particles != null:
		particles.color = main_color

# يجمع عقد الرسم التي تتحرك مع الجزرة
func _visual_nodes() -> Array[Node2D]:
	var nodes: Array[Node2D] = []
	for node_name in ["Glow", "Shadow", "Body", "BodyOutline", "Highlight", "StripeTop", "StripeMiddle", "StripeBottom", "LeafLeft", "LeafCenter", "LeafRight", "LeafShine"]:
		var node := get_node_or_null(node_name) as Node2D
		if node != null:
			nodes.append(node)
	return nodes

# يحدث المنطق المتكرر في كل اطار عادي
func _process(delta: float) -> void:
	if collected:
		return

	if not _bob_ready:
		bob_offset = position.y
		_bob_ready = true
	bob_time += delta
	position.y = bob_offset + sin(bob_time * 2.8) * 5.0
	rotation = sin(bob_time * 2.0) * 0.045

# يرجع عدد النقاط التي تعطيها الجزرة
func get_points() -> int:
	return 25 if is_golden else 10

# يرجع عدد الجزر التي تضاف للمحفظة
func get_currency_value() -> int:
	return 1

# ينفذ عملية جمع الجزرة ويخفيها ويطلق مؤثراتها
func collect() -> void:
	if collected:
		return
	collected = true
	collected_for_respawn.emit(is_golden, global_position)
	set_deferred("monitoring", false)
	for node in _visual_nodes():
		node.visible = false
	if particles != null:
		particles.emitting = true
	await get_tree().create_timer(0.5).timeout
	queue_free()
