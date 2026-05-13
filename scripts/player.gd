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
const IDLE_BREATHE_SPEED: float = 3.2
const IDLE_BREATHE_HEIGHT: float = 2.4
const WALK_HOP_SPEED: float = 11.5
const DASH_HOP_SPEED: float = 19.5
const DAMAGE_REACTION_DURATION: float = 0.34
const LANDING_SQUASH_DURATION: float = 0.12

var invincible:      bool  = false
var invincible_timer: float = 0.0

var _dashing:       bool   = false
var _dash_timer:    float  = 0.0
var _dash_cooldown: float  = 0.0
var _dash_dir:      Vector2 = Vector2.RIGHT
var _hop_time:      float = 0.0
var _idle_time:     float = 0.0
var _landing_squash_timer: float = 0.0
var _damage_reaction_timer: float = 0.0
var _was_moving_last_frame: bool = false
var _current_bunny_animation: String = ""
var _bunny_icon_base_position: Vector2 = Vector2.ZERO
var _bunny_icon_base_scale: Vector2 = Vector2.ONE
var _bunny_icon_base_tint: Color = Color.WHITE
var _bunny_frames_base_position: Vector2 = Vector2.ZERO
var _bunny_frames_base_scale: Vector2 = Vector2.ONE
var _skin_badge_base_position: Vector2 = Vector2.ZERO
var _bunny_facing_right: bool = true
var _use_white_bunny_frames: bool = false
var _skin_badge: Label

@onready var sprite:  ColorRect = $Sprite
@onready var ear_l:   ColorRect = $EarLeft
@onready var ear_r:   ColorRect = $EarRight
@onready var tail:    ColorRect = $Tail
@onready var pickup:  Area2D    = $PickupArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var pickup_collision: CollisionShape2D = $PickupArea/PickupCollision
@onready var bunny_icon: Label = $BunnyIcon
@onready var bunny_frames: AnimatedSprite2D = $BunnyFrames
@onready var shadow: ColorRect = $Shadow

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
	_use_white_bunny_frames = str(skin.get("id", "")) == "white_bunny" and bunny_frames != null
	if bunny_icon:
		bunny_icon.text = str(skin["icon"])
		var icon_tint: Color = col
		if skin.has("icon_tint") and skin["icon_tint"] is Color:
			icon_tint = skin["icon_tint"]
		_bunny_icon_base_tint = icon_tint
		bunny_icon.modulate = icon_tint
		bunny_icon.add_theme_color_override("font_color", icon_tint)
		bunny_icon.add_theme_font_size_override("font_size", int(skin.get("icon_font_size", 58)))
		_bunny_icon_base_position = bunny_icon.position
		var visual_scale := float(skin.get("visual_scale", 1.0))
		_bunny_icon_base_scale = Vector2(abs(bunny_icon.scale.x), abs(bunny_icon.scale.y)) * visual_scale
		bunny_icon.pivot_offset = bunny_icon.size * 0.5
		bunny_icon.visible = not _use_white_bunny_frames
		_apply_skin_badge(str(skin.get("badge", "")), skin.get("badge_offset", Vector2(17.0, -58.0)))
	if bunny_frames:
		bunny_frames.visible = _use_white_bunny_frames
		_bunny_frames_base_position = bunny_frames.position
		_bunny_frames_base_scale = Vector2(abs(bunny_frames.scale.x), abs(bunny_frames.scale.y))
		if _use_white_bunny_frames:
			bunny_frames.play("idle")
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
	if _landing_squash_timer > 0.0:
		_landing_squash_timer = max(_landing_squash_timer - delta, 0.0)
	if _damage_reaction_timer > 0.0:
		_damage_reaction_timer = max(_damage_reaction_timer - delta, 0.0)

	# ── Active dash movement (ignores normal input while dashing) ────────────
	if _dashing:
		_dash_timer -= delta
		velocity = _dash_dir * DASH_SPEED
		move_and_slide()
		_keep_inside_world()
		_animate_bunny(delta, _dash_dir, true)
		if _dash_timer <= 0.0:
			_dashing = false
			_landing_squash_timer = LANDING_SQUASH_DURATION
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
	if not _has_active_bunny_visual():
		return
	var t: float = min(delta * (14.0 if dash_active else 10.0), 1.0)
	var moving := dir.length() > 0.0
	if abs(dir.x) > 0.05:
		# Face only the visual toward the last horizontal movement direction.
		# The physics root stays positive to avoid mirrored collisions.
		_bunny_facing_right = dir.x > 0.0
	if _damage_reaction_timer > 0.0:
		_play_white_bunny_animation("hurt", 1.25)
		_apply_damage_reaction(delta, dir, t)
		_was_moving_last_frame = moving
		return
	if not moving:
		_idle_time += delta
		_hop_time = 0.0
		_play_white_bunny_animation("idle", 1.0)
		var idle_bob := (sin(_idle_time * IDLE_BREATHE_SPEED) + 1.0) * 0.5 * IDLE_BREATHE_HEIGHT
		var idle_squash := 0.08 + (sin(_idle_time * IDLE_BREATHE_SPEED + PI * 0.45) + 1.0) * 0.025
		var landing_ratio := _get_landing_squash_ratio()
		_lerp_bunny_visual_transform(idle_bob, idle_squash + landing_ratio * 0.34, 0.0, t)
		_was_moving_last_frame = false
		return
	if not _was_moving_last_frame:
		_landing_squash_timer = LANDING_SQUASH_DURATION * 0.55
	_idle_time = 0.0
	_play_white_bunny_animation("dash" if dash_active else "hop", 1.35 if dash_active else 1.0)
	_hop_time += delta * (DASH_HOP_SPEED if dash_active else WALK_HOP_SPEED)
	var hop_wave := abs(sin(_hop_time))
	var hop := hop_wave * (13.5 if dash_active else 8.5)
	var stride_squash := pow(1.0 - hop_wave, 2.0) * (0.34 if dash_active else 0.24)
	var landing_squash := _get_landing_squash_ratio() * 0.28
	var direction_lean := clamp(dir.x, -1.0, 1.0) * (0.18 if dash_active else 0.10)
	var vertical_lean := clamp(dir.y, -1.0, 1.0) * 0.04
	var forward_offset := Vector2((_get_bunny_facing_sign() * (5.0 if dash_active else 2.0)), 0.0)
	_set_bunny_visual_transform(hop, stride_squash + landing_squash, direction_lean + vertical_lean, forward_offset)
	_was_moving_last_frame = true

func _apply_damage_reaction(_delta: float, _dir: Vector2, weight: float) -> void:
	var progress := 1.0 - (_damage_reaction_timer / DAMAGE_REACTION_DURATION)
	var shake := sin(progress * TAU * 5.0) * (1.0 - progress)
	var facing := _get_bunny_facing_sign()
	var recoil := Vector2(-facing * 5.0 * (1.0 - progress), -4.0 * (1.0 - progress))
	var squash := 0.30 * (1.0 - progress)
	_lerp_bunny_visual_transform(2.0, squash, shake * 0.24, weight, recoil)
	_set_bunny_visual_tint(Color(1.0, 0.72, 0.72, 1.0).lerp(Color.WHITE, progress))

func _set_bunny_visual_transform(hop: float, squash: float, rotation_value: float, local_offset: Vector2 = Vector2.ZERO) -> void:
	var target_position := _get_bunny_base_position() + local_offset + Vector2(0.0, -hop)
	var target_scale := _get_bunny_facing_scale(squash)
	if _use_white_bunny_frames and bunny_frames != null:
		bunny_frames.position = target_position
		bunny_frames.scale = target_scale
		bunny_frames.rotation = rotation_value
	elif bunny_icon != null:
		bunny_icon.position = target_position
		bunny_icon.scale = target_scale
		bunny_icon.rotation = rotation_value
	_update_shadow_for_hop(hop, squash)
	_set_bunny_visual_tint(Color.WHITE)
	if _skin_badge != null:
		_skin_badge.position = _skin_badge_base_position + local_offset + Vector2(0.0, -hop)
		_skin_badge.rotation = rotation_value

func _lerp_bunny_visual_transform(hop: float, squash: float, rotation_value: float, weight: float, local_offset: Vector2 = Vector2.ZERO) -> void:
	var target_position := _get_bunny_base_position() + local_offset + Vector2(0.0, -hop)
	var target_scale := _get_bunny_facing_scale(squash)
	if _use_white_bunny_frames and bunny_frames != null:
		bunny_frames.position = bunny_frames.position.lerp(target_position, weight)
		bunny_frames.scale = bunny_frames.scale.lerp(target_scale, weight)
		bunny_frames.rotation = lerp(bunny_frames.rotation, rotation_value, weight)
	elif bunny_icon != null:
		bunny_icon.position = bunny_icon.position.lerp(target_position, weight)
		bunny_icon.scale = bunny_icon.scale.lerp(target_scale, weight)
		bunny_icon.rotation = lerp(bunny_icon.rotation, rotation_value, weight)
	_update_shadow_for_hop(hop, squash)
	if _skin_badge != null:
		_skin_badge.position = _skin_badge.position.lerp(_skin_badge_base_position + local_offset + Vector2(0.0, -hop), weight)
		_skin_badge.rotation = lerp(_skin_badge.rotation, rotation_value, weight)

func _has_active_bunny_visual() -> bool:
	return (_use_white_bunny_frames and bunny_frames != null) or bunny_icon != null

func _get_bunny_base_position() -> Vector2:
	if _use_white_bunny_frames:
		return _bunny_frames_base_position
	return _bunny_icon_base_position

func _play_white_bunny_animation(animation_name: String, speed_scale: float) -> void:
	if not _use_white_bunny_frames or bunny_frames == null:
		return
	bunny_frames.speed_scale = speed_scale
	if _current_bunny_animation != animation_name or bunny_frames.animation != animation_name:
		_current_bunny_animation = animation_name
		bunny_frames.play(animation_name)

func _update_shadow_for_hop(hop: float, squash: float) -> void:
	if shadow == null:
		return
	var lift_ratio: float = clamp(hop / 13.5, 0.0, 1.0)
	shadow.scale = Vector2(1.0 - lift_ratio * 0.22 + squash * 0.10, 1.0 - lift_ratio * 0.18 + squash * 0.06)
	shadow.modulate.a = 1.0 - lift_ratio * 0.32

func _get_bunny_facing_scale(squash: float) -> Vector2:
	var base_scale := _bunny_frames_base_scale if _use_white_bunny_frames else _bunny_icon_base_scale
	var facing_sign := _get_bunny_facing_sign()
	if not _use_white_bunny_frames:
		# The fallback side-view rabbit glyph points left by default, so a
		# right-facing emoji bunny must be mirrored.
		facing_sign = -1.0 if _bunny_facing_right else 1.0
	return base_scale * Vector2(
		facing_sign * (1.0 + squash * 0.10),
		1.0 - squash * 0.08
	)

func _get_bunny_facing_sign() -> float:
	return 1.0 if _bunny_facing_right else -1.0

func _get_landing_squash_ratio() -> float:
	if _landing_squash_timer <= 0.0:
		return 0.0
	return _landing_squash_timer / LANDING_SQUASH_DURATION

func _set_bunny_visual_tint(tint: Color) -> void:
	if _use_white_bunny_frames and bunny_frames != null:
		bunny_frames.modulate = tint
	elif bunny_icon != null:
		bunny_icon.modulate = _bunny_icon_base_tint * tint

func _keep_inside_world() -> void:
	global_position = global_position.clamp(WORLD_MIN, WORLD_MAX)

func take_damage() -> void:
	if invincible:
		return
	invincible       = true
	invincible_timer = INVINCIBLE_DURATION
	_damage_reaction_timer = DAMAGE_REACTION_DURATION
	_landing_squash_timer = LANDING_SQUASH_DURATION
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
