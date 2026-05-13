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
const SPOTTED_BUNNY_SKIN_ID: String = "spotted_bunny"
const SPOTTED_BUNNY_SHEET_PATH: String = "res://assets/Gemini_Generated_Image_z29tj3z29tj3z29t-removebg-preview.png"

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
var _bunny_icon_base_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
var _bunny_frames_base_position: Vector2 = Vector2.ZERO
var _bunny_frames_base_scale: Vector2 = Vector2.ONE
var _bunny_frames_base_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
var _default_bunny_sprite_frames: SpriteFrames
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
	if sprite != null:
		sprite.color = col
	if ear_l != null:
		ear_l.color = col
	if ear_r != null:
		ear_r.color = col
	if tail != null:
		tail.color = tail_col
	_apply_skin_physics(skin)
	var skin_id: String = str(skin.get("id", ""))
	_use_white_bunny_frames = _skin_uses_sprite_frames(skin_id) and bunny_frames != null
	if bunny_icon != null:
		bunny_icon.text = str(skin["icon"])
		var icon_tint: Color = col
		if skin.has("icon_tint") and skin["icon_tint"] is Color:
			icon_tint = skin["icon_tint"]
		_bunny_icon_base_tint = icon_tint
		_bunny_frames_base_tint = _get_sprite_frame_tint(skin, icon_tint)
		bunny_icon.modulate = icon_tint
		bunny_icon.add_theme_color_override("font_color", icon_tint)
		bunny_icon.add_theme_font_size_override("font_size", int(skin.get("icon_font_size", 58)))
		_bunny_icon_base_position = bunny_icon.position
		var visual_scale: float = float(skin.get("visual_scale", 1.0))
		_bunny_icon_base_scale = Vector2(abs(bunny_icon.scale.x), abs(bunny_icon.scale.y)) * visual_scale
		bunny_icon.pivot_offset = bunny_icon.size * 0.5
		bunny_icon.visible = not _use_white_bunny_frames
		_apply_skin_badge(str(skin.get("badge", "")), skin.get("badge_offset", Vector2(17.0, -58.0)))
	if bunny_frames != null:
		if _default_bunny_sprite_frames == null:
			_default_bunny_sprite_frames = bunny_frames.sprite_frames
		_apply_sprite_sheet_for_skin(skin_id)
		bunny_frames.visible = _use_white_bunny_frames
		_bunny_frames_base_position = bunny_frames.position
		_bunny_frames_base_scale = Vector2(abs(bunny_frames.scale.x), abs(bunny_frames.scale.y))
		if _use_white_bunny_frames:
			bunny_frames.play("idle")
	_set_bunny_visual_transform(0.0, 0.0, 0.0, Vector2.ZERO)
	# Connect pickup area for carrot detection
	if pickup != null:
		pickup.area_entered.connect(_on_pickup_area_entered)

func _skin_uses_sprite_frames(skin_id: String) -> bool:
	# Use the same hand-drawn bunny sheet for every playable bunny skin, then
	# tint it per skin so brown/dune/snow bunnies animate like the white one.
	return skin_id.ends_with("_bunny") or skin_id == "dune_hare" or skin_id == "snow_scout"

func _get_sprite_frame_tint(skin: Dictionary, fallback_tint: Color) -> Color:
	var skin_id: String = str(skin.get("id", ""))
	if skin_id == "white_bunny":
		return Color(1.0, 1.0, 1.0, 1.0)
	if skin_id == SPOTTED_BUNNY_SKIN_ID and ResourceLoader.exists(SPOTTED_BUNNY_SHEET_PATH):
		return Color(1.0, 1.0, 1.0, 1.0)
	if skin.has("icon_tint") and skin["icon_tint"] is Color:
		return skin["icon_tint"]
	return fallback_tint

func _apply_sprite_sheet_for_skin(skin_id: String) -> void:
	if bunny_frames == null:
		return
	if _default_bunny_sprite_frames != null:
		bunny_frames.sprite_frames = _default_bunny_sprite_frames
	if skin_id != SPOTTED_BUNNY_SKIN_ID:
		return
	var spotted_frames: SpriteFrames = _build_spotted_bunny_sprite_frames()
	if spotted_frames != null:
		bunny_frames.sprite_frames = spotted_frames
		_bunny_frames_base_tint = Color(1.0, 1.0, 1.0, 1.0)

func _build_spotted_bunny_sprite_frames() -> SpriteFrames:
	if not ResourceLoader.exists(SPOTTED_BUNNY_SHEET_PATH):
		push_warning("Missing spotted bunny sheet: " + SPOTTED_BUNNY_SHEET_PATH)
		return null
	var texture: Texture2D = load(SPOTTED_BUNNY_SHEET_PATH) as Texture2D
	if texture == null:
		return null
	var cell_size: Vector2 = Vector2(float(texture.get_width()) / 7.0, float(texture.get_height()) / 4.0)
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_spotted_animation(frames, texture, cell_size, "idle", [0, 1, 2, 3, 4, 3, 2, 1], 0, 5.5, true)
	_add_spotted_animation(frames, texture, cell_size, "hop", [0, 1, 2, 3, 4, 5, 6], 0, 13.0, true)
	_add_spotted_animation(frames, texture, cell_size, "dash", [0, 1, 2, 4, 5, 6], 1, 18.0, true)
	_add_spotted_animation(frames, texture, cell_size, "hurt", [3, 2, 1, 0], 1, 10.0, false)
	return frames

func _add_spotted_animation(frames: SpriteFrames, texture: Texture2D, cell_size: Vector2, animation_name: String, columns: Array, row: int, speed: float, loop: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop)
	frames.set_animation_speed(animation_name, speed)
	for column in columns:
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(float(column) * cell_size.x, float(row) * cell_size.y, cell_size.x, cell_size.y)
		frames.add_frame(animation_name, atlas, 1.0)

func _apply_skin_physics(skin: Dictionary) -> void:
	if collision_shape != null and collision_shape.shape is CapsuleShape2D:
		var body_shape: CapsuleShape2D = collision_shape.shape.duplicate() as CapsuleShape2D
		body_shape.height = float(skin.get("collision_height", 42.0))
		body_shape.radius = float(skin.get("collision_radius", 18.0))
		collision_shape.shape = body_shape
	if pickup_collision != null and pickup_collision.shape is CircleShape2D:
		var pickup_shape: CircleShape2D = pickup_collision.shape.duplicate() as CircleShape2D
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
	if badge_offset is Vector2:
		_skin_badge_base_position = badge_offset
	else:
		_skin_badge_base_position = Vector2(17.0, -58.0)
	_skin_badge.text = badge
	_skin_badge.visible = badge != ""

func _physics_process(delta: float) -> void:
	# ── Invincibility countdown + flash ──────────────────────────────────────
	if invincible:
		invincible_timer -= delta
		if int(invincible_timer * 8) % 2 == 0:
			modulate.a = 0.3
		else:
			modulate.a = 1.0
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
	var dir: Vector2 = Vector2.ZERO
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
	var can_dash: bool = _dash_cooldown <= 0.0 and dir.length() > 0.0
	if Input.is_action_just_pressed("ui_accept") and can_dash:
		_dashing = true
		_dash_timer = DASH_DURATION
		_dash_cooldown = DASH_COOLDOWN
	velocity = dir * SPEED
	move_and_slide()
	_keep_inside_world()
	_animate_bunny(delta, dir, false)

func _animate_bunny(delta: float, dir: Vector2, dash_active: bool) -> void:
	if not _has_active_bunny_visual():
		return

	var blend_speed: float = 10.0
	if dash_active:
		blend_speed = 14.0
	var blend_weight: float = min(delta * blend_speed, 1.0)
	var moving: bool = dir.length() > 0.0

	if abs(dir.x) > 0.05:
		# Face only the visual toward the last horizontal movement direction.
		# The physics root stays positive to avoid mirrored collisions.
		_bunny_facing_right = dir.x > 0.0

	if _damage_reaction_timer > 0.0:
		_play_white_bunny_animation("hurt", 1.25)
		_apply_damage_reaction(delta, dir, blend_weight)
		_was_moving_last_frame = moving
		return
	if not _was_moving_last_frame:
		_landing_squash_timer = LANDING_SQUASH_DURATION * 0.55
	_idle_time = 0.0
	var animation_name := "hop"
	var animation_speed := 1.0
	if dash_active:
		animation_name = "dash"
		animation_speed = 1.35
	_play_white_bunny_animation(animation_name, animation_speed)
	var hop_speed := WALK_HOP_SPEED
	if dash_active:
		hop_speed = DASH_HOP_SPEED
	_hop_time += delta * hop_speed
	var hop_wave := abs(sin(_hop_time))
	var hop_height := 8.5
	var squash_strength := 0.24
	if dash_active:
		hop_height = 13.5
		squash_strength = 0.34
	var hop := hop_wave * hop_height
	var stride_squash := pow(1.0 - hop_wave, 2.0) * squash_strength
	var landing_squash := _get_landing_squash_ratio() * 0.28
	var lean_strength := 0.10
	var forward_strength := 2.0
	if dash_active:
		lean_strength = 0.18
		forward_strength = 5.0
	var direction_lean := clamp(dir.x, -1.0, 1.0) * lean_strength
	var vertical_lean := clamp(dir.y, -1.0, 1.0) * 0.04
	var forward_offset := Vector2(_get_bunny_facing_sign() * forward_strength, 0.0)
	_set_bunny_visual_transform(hop, stride_squash + landing_squash, direction_lean + vertical_lean, forward_offset)
	_was_moving_last_frame = true

	if moving:
		_animate_moving_bunny(delta, dir, dash_active)
	else:
		_animate_idle_bunny(delta, blend_weight)

func _animate_idle_bunny(delta: float, blend_weight: float) -> void:
	_idle_time += delta
	_hop_time = 0.0
	_play_white_bunny_animation("idle", 1.0)
	var idle_bob: float = (sin(_idle_time * IDLE_BREATHE_SPEED) + 1.0) * 0.5 * IDLE_BREATHE_HEIGHT
	var idle_squash: float = 0.08 + (sin(_idle_time * IDLE_BREATHE_SPEED + PI * 0.45) + 1.0) * 0.025
	var landing_ratio: float = _get_landing_squash_ratio()
	_lerp_bunny_visual_transform(idle_bob, idle_squash + landing_ratio * 0.34, 0.0, blend_weight, Vector2.ZERO)
	_was_moving_last_frame = false

func _animate_moving_bunny(delta: float, dir: Vector2, dash_active: bool) -> void:
	if not _was_moving_last_frame:
		_landing_squash_timer = LANDING_SQUASH_DURATION * 0.55
	_idle_time = 0.0

	var animation_name: String = "hop"
	var animation_speed: float = 1.0
	var hop_speed: float = WALK_HOP_SPEED
	var hop_height: float = 8.5
	var squash_strength: float = 0.24
	var lean_strength: float = 0.10
	var forward_strength: float = 2.0

	if dash_active:
		animation_name = "dash"
		animation_speed = 1.35
		hop_speed = DASH_HOP_SPEED
		hop_height = 13.5
		squash_strength = 0.34
		lean_strength = 0.18
		forward_strength = 5.0

	_play_white_bunny_animation(animation_name, animation_speed)
	_hop_time += delta * hop_speed
	var hop_wave: float = abs(sin(_hop_time))
	var hop: float = hop_wave * hop_height
	var stride_squash: float = pow(1.0 - hop_wave, 2.0) * squash_strength
	var landing_squash: float = _get_landing_squash_ratio() * 0.28
	var direction_lean: float = clamp(dir.x, -1.0, 1.0) * lean_strength
	var vertical_lean: float = clamp(dir.y, -1.0, 1.0) * 0.04
	var forward_offset: Vector2 = Vector2(_get_bunny_facing_sign() * forward_strength, 0.0)
	_set_bunny_visual_transform(hop, stride_squash + landing_squash, direction_lean + vertical_lean, forward_offset)
	_was_moving_last_frame = true

func _apply_damage_reaction(_delta: float, _dir: Vector2, weight: float) -> void:
	var progress: float = 1.0 - (_damage_reaction_timer / DAMAGE_REACTION_DURATION)
	var shake: float = sin(progress * PI * 10.0) * (1.0 - progress)
	var facing: float = _get_bunny_facing_sign()
	var recoil: Vector2 = Vector2(-facing * 5.0 * (1.0 - progress), -4.0 * (1.0 - progress))
	var squash: float = 0.30 * (1.0 - progress)
	_lerp_bunny_visual_transform(2.0, squash, shake * 0.24, weight, recoil)
	var damage_tint: Color = Color(1.0, 0.72, 0.72, 1.0)
	_set_bunny_visual_tint(damage_tint.lerp(Color(1.0, 1.0, 1.0, 1.0), progress))

func _set_bunny_visual_transform(hop: float, squash: float, rotation_value: float, local_offset: Vector2) -> void:
	var target_position: Vector2 = _get_bunny_base_position() + local_offset + Vector2(0.0, -hop)
	var target_scale: Vector2 = _get_bunny_facing_scale(squash)
	if _use_white_bunny_frames and bunny_frames != null:
		bunny_frames.position = target_position
		bunny_frames.scale = target_scale
		bunny_frames.rotation = rotation_value
	elif bunny_icon != null:
		bunny_icon.position = target_position
		bunny_icon.scale = target_scale
		bunny_icon.rotation = rotation_value
	_update_shadow_for_hop(hop, squash)
	_set_bunny_visual_tint(Color(1.0, 1.0, 1.0, 1.0))
	if _skin_badge != null:
		_skin_badge.position = _skin_badge_base_position + local_offset + Vector2(0.0, -hop)
		_skin_badge.rotation = rotation_value

func _lerp_bunny_visual_transform(hop: float, squash: float, rotation_value: float, weight: float, local_offset: Vector2) -> void:
	var target_position: Vector2 = _get_bunny_base_position() + local_offset + Vector2(0.0, -hop)
	var target_scale: Vector2 = _get_bunny_facing_scale(squash)
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
	var base_scale: Vector2 = _bunny_icon_base_scale
	if _use_white_bunny_frames:
		base_scale = _bunny_frames_base_scale
	var facing_sign: float = _get_bunny_facing_sign()
	if not _use_white_bunny_frames:
		# The fallback side-view rabbit glyph points left by default, so a
		# right-facing emoji bunny must be mirrored.
		if _bunny_facing_right:
			facing_sign = -1.0
		else:
			facing_sign = 1.0
	return base_scale * Vector2(
		facing_sign * (1.0 + squash * 0.10),
		1.0 - squash * 0.08
	)

func _get_bunny_facing_sign() -> float:
	if _bunny_facing_right:
		return 1.0
	return -1.0

func _get_landing_squash_ratio() -> float:
	if _landing_squash_timer <= 0.0:
		return 0.0
	return _landing_squash_timer / LANDING_SQUASH_DURATION

func _set_bunny_visual_tint(tint: Color) -> void:
	if _use_white_bunny_frames and bunny_frames != null:
		bunny_frames.modulate = _bunny_frames_base_tint * tint
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
		var currency_value: int = 1
		if area.has_method("get_currency_value"):
			currency_value = area.get_currency_value()
		GameManager.add_score(points, currency_value)
		if points >= 25:
			AudioManager.play_golden_collect()
		else:
			AudioManager.play_collect()
		area.collect()
