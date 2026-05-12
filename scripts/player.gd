extends CharacterBody2D

# =============================================
# Player — Bunny Controller
# Controls: WASD / Arrow keys to move
#           Space / Enter  to DASH (short speed burst, 1.2 s cooldown)
# =============================================

const SPEED:             float = 220.0
const DASH_SPEED:        float = 540.0
const DASH_DURATION:     float = 0.16
const DASH_COOLDOWN:     float = 1.2
const INVINCIBLE_DURATION: float = 1.5
const WORLD_MIN: Vector2 = Vector2(32.0, 88.0)
const WORLD_MAX: Vector2 = Vector2(992.0, 694.0)

var invincible:      bool  = false
var invincible_timer: float = 0.0

var _dashing:       bool   = false
var _dash_timer:    float  = 0.0
var _dash_cooldown: float  = 0.0
var _dash_dir:      Vector2 = Vector2.RIGHT
var _hop_time:      float = 0.0
var _bunny_icon_base_position: Vector2 = Vector2.ZERO
var _bunny_icon_base_scale: Vector2 = Vector2.ONE
var _skin_badge_base_position: Vector2 = Vector2.ZERO
var _bunny_facing_right: bool = true
var _skin_badge: Label

@onready var sprite:  ColorRect = $Sprite
@onready var ear_l:   ColorRect = $EarLeft
@onready var ear_r:   ColorRect = $EarRight
@onready var tail:    ColorRect = $Tail
@onready var pickup:  Area2D    = $PickupArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var pickup_collision: CollisionShape2D = $PickupArea/PickupCollision
@onready var bunny_icon: Label = $BunnyIcon

func _ready() -> void:
	add_to_group("player")
	# Apply selected skin visuals and matching physics shape.
	var skin: Dictionary = GameManager.get_selected_skin_data()
	var col: Color = skin["body_color"]
	var tail_col: Color = skin["tail_color"]
	if sprite: sprite.color = col
	if ear_l:  ear_l.color  = col
	if ear_r:  ear_r.color  = col
	if tail:   tail.color   = tail_col
	_apply_skin_physics(skin)
	if bunny_icon:
		bunny_icon.text = str(skin["icon"])
		bunny_icon.add_theme_font_size_override("font_size", int(skin.get("icon_font_size", 58)))
		_bunny_icon_base_position = bunny_icon.position
		var visual_scale := float(skin.get("visual_scale", 1.0))
		_bunny_icon_base_scale = Vector2(abs(bunny_icon.scale.x), abs(bunny_icon.scale.y)) * visual_scale
		bunny_icon.pivot_offset = bunny_icon.size * 0.5
		_apply_skin_badge(str(skin.get("badge", "")), skin.get("badge_offset", Vector2(17.0, -58.0)))
		_set_bunny_visual_transform(0.0, 0.0, 0.0)
	# Connect pickup area for carrot detection
	if pickup:
		pickup.area_entered.connect(_on_pickup_area_entered)

func _apply_skin_physics(skin: Dictionary) -> void:
	if collision_shape != null and collision_shape.shape is CapsuleShape2D:
		var body_shape := collision_shape.shape.duplicate() as CapsuleShape2D
		body_shape.height = float(skin.get("collision_height", 42.0))
		body_shape.radius = float(skin.get("collision_radius", 18.0))
		collision_shape.shape = body_shape
	if pickup_collision != null and pickup_collision.shape is CircleShape2D:
		var pickup_shape := pickup_collision.shape.duplicate() as CircleShape2D
		pickup_shape.radius = float(skin.get("pickup_radius", 34.0))
		pickup_collision.shape = pickup_shape

func _apply_skin_badge(badge: String, badge_offset: Variant) -> void:
	if _skin_badge == null:
		_skin_badge = Label.new()
		_skin_badge.name = "SkinBadge"
		_skin_badge.size = Vector2(34, 34)
		_skin_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_skin_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_skin_badge.add_theme_font_size_override("font_size", 24)
		add_child(_skin_badge)
	_skin_badge_base_position = badge_offset if badge_offset is Vector2 else Vector2(17.0, -58.0)
	_skin_badge.text = badge
	_skin_badge.visible = badge != ""

func _physics_process(delta: float) -> void:
	# ── Invincibility countdown + flash ──────────────────────────────────────
	if invincible:
		invincible_timer -= delta
		modulate.a = 0.3 if int(invincible_timer * 8) % 2 == 0 else 1.0
		if invincible_timer <= 0.0:
			invincible  = false
			modulate.a  = 1.0

	# ── Dash cooldown tick ───────────────────────────────────────────────────
	if _dash_cooldown > 0.0:
		_dash_cooldown -= delta

	# ── Active dash movement (ignores normal input while dashing) ────────────
	if _dashing:
		_dash_timer -= delta
		velocity = _dash_dir * DASH_SPEED
		move_and_slide()
		_keep_inside_world()
		_animate_bunny(delta, _dash_dir, true)
		if _dash_timer <= 0.0:
			_dashing = false
		return

	# ── Read directional input ───────────────────────────────────────────────
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		dir.x += 1.0
	if Input.is_action_pressed("ui_left")  or Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_down")  or Input.is_action_pressed("move_down"):
		dir.y += 1.0
	if Input.is_action_pressed("ui_up")    or Input.is_action_pressed("move_up"):
		dir.y -= 1.0

	if dir.length() > 0.0:
		dir = dir.normalized()
		# Keep the CharacterBody scale positive so the bunny icon, collision,
		# and pickup area do not mirror or jitter when moving left.
		scale.x = abs(scale.x)
		_dash_dir = dir

	# ── Trigger dash (Space or Enter while moving) ───────────────────────────
	if Input.is_action_just_pressed("ui_accept") \
			and _dash_cooldown <= 0.0 \
			and dir.length() > 0.0:
		_dashing      = true
		_dash_timer   = DASH_DURATION
		_dash_cooldown = DASH_COOLDOWN

	velocity = dir * SPEED
	move_and_slide()
	_keep_inside_world()
	_animate_bunny(delta, dir, false)

func _animate_bunny(delta: float, dir: Vector2, dash_active: bool) -> void:
	if not bunny_icon:
		return
	var t: float = min(delta * 10.0, 1.0)
	if abs(dir.x) > 0.05:
		# The bunny emoji artwork renders facing left in-game, so mirror only
		# the visual Label when moving right. The physics root stays positive.
		_bunny_facing_right = dir.x > 0.0

	if dir.length() <= 0.0:
		_hop_time = 0.0
		_lerp_bunny_visual_transform(0.0, 0.0, 0.0, t)
		return

	_hop_time += delta * (18.0 if dash_active else 11.0)
	var hop: float = abs(sin(_hop_time)) * (12.0 if dash_active else 8.0)
	var squash: float = abs(sin(_hop_time * 1.15))
	var tilt_sign: float = 1.0 if _bunny_facing_right else -1.0
	var tilt: float = tilt_sign * (0.16 if dash_active else 0.09)
	_set_bunny_visual_transform(hop, squash, tilt)

func _set_bunny_visual_transform(hop: float, squash: float, rotation_value: float) -> void:
	bunny_icon.position = _bunny_icon_base_position + Vector2(0.0, -hop)
	bunny_icon.scale = _get_bunny_facing_scale(squash)
	bunny_icon.rotation = rotation_value
	if _skin_badge != null:
		_skin_badge.position = _skin_badge_base_position + Vector2(0.0, -hop)
		_skin_badge.rotation = rotation_value

func _lerp_bunny_visual_transform(hop: float, squash: float, rotation_value: float, weight: float) -> void:
	bunny_icon.position = bunny_icon.position.lerp(_bunny_icon_base_position + Vector2(0.0, -hop), weight)
	bunny_icon.scale = bunny_icon.scale.lerp(_get_bunny_facing_scale(squash), weight)
	bunny_icon.rotation = lerp(bunny_icon.rotation, rotation_value, weight)
	if _skin_badge != null:
		_skin_badge.position = _skin_badge.position.lerp(_skin_badge_base_position + Vector2(0.0, -hop), weight)
		_skin_badge.rotation = lerp(_skin_badge.rotation, rotation_value, weight)

func _get_bunny_facing_scale(squash: float) -> Vector2:
	var facing_sign := -1.0 if _bunny_facing_right else 1.0
	return _bunny_icon_base_scale * Vector2(
		facing_sign * (1.0 + squash * 0.05),
		1.0 - squash * 0.04
	)

func _keep_inside_world() -> void:
	global_position = global_position.clamp(WORLD_MIN, WORLD_MAX)

func take_damage() -> void:
	if invincible:
		return
	invincible       = true
	invincible_timer = INVINCIBLE_DURATION
	AudioManager.play_damage()
	GameManager.lose_life()

func _on_pickup_area_entered(area: Area2D) -> void:
	if area.is_in_group("carrot"):
		var points: int = area.get_points()
		var currency_value: int = area.get_currency_value() if area.has_method("get_currency_value") else 1
		GameManager.add_score(points, currency_value)
		if points >= 25:
			AudioManager.play_golden_collect()
		else:
			AudioManager.play_collect()
		area.collect()
