extends CharacterBody2D

# يتحكم في الثعلب العدو من ناحية المطاردة والدورية والحركة والاصطدام باللاعب

# قيم ثابتة يستخدمها هذا السكربت اثناء التشغيل
const NEW_FOX_SHEET_PATH: String = "res://assets/Gemini_Generated_Image_7zbfmh7zbfmh7zbf-removebg-preview.png"
const FOX_SHEET_COLUMNS: int = 7
const FOX_SHEET_ROWS: int = 4

# قيم قابلة للتعديل من داخل المحرر لضبط سلوك المشهد
@export var patrol_distance: float = 100.0
@export var patrol_speed: float = 72.0
@export var chase_speed: float = 154.0
@export var chase_range: float = 9999.0
@export var acceleration: float = 520.0
@export var arrival_distance: float = 52.0
@export var separation_distance: float = 72.0
@export var separation_strength: float = 150.0
@export var attack_recoil_speed: float = 210.0
@export var attack_pause_duration: float = 0.45
@export var damage_cooldown: float = 0.9
@export var chase_flank_angle: float = 0.0
@export var chase_flank_distance: float = 0.0
@export var chase_entry_distance: float = 0.0
@export var chase_flank_side: float = 0.0
@export var chase_lead_distance: float = 0.0
@export var chase_weave_strength: float = 0.0
@export var chase_weave_phase: float = 0.0
@export var chase_route_distance: float = 160.0
@export var chase_route_entry_distance: float = 110.0
@export var chase_route_release_distance: float = 260.0
@export var chase_orbit_strength: float = 0.0
@export var chase_orbit_direction: float = 1.0
@export var move_right_first: bool = true

# متغيرات تحفظ حالة هذا السكربت اثناء اللعب
var start_pos: Vector2 = Vector2.ZERO
var dir: float = 1.0
var _player: Node2D = null
var _base_scale: Vector2 = Vector2.ONE
var _facing_left: bool = false
var _visual_rects: Array[ColorRect] = []
var _visual_offsets: Dictionary = {}
var _attack_pause_timer: float = 0.0
var _damage_cooldown_timer: float = 0.0
var _walk_time: float = 0.0
var _use_new_fox_frames: bool = false
var _fox_frames_base_position: Vector2 = Vector2.ZERO
var _fox_frames_base_scale: Vector2 = Vector2.ONE

# مراجع جاهزة لعقد المشهد حتى يتم تعديل النصوص والازرار والرسوم بسرعة
@onready var hurt_area: Area2D = $HurtArea
@onready var fox_frames: AnimatedSprite2D = get_node_or_null("FoxFrames") as AnimatedSprite2D
@onready var shadow: ColorRect = get_node_or_null("Shadow") as ColorRect

# يبدأ تجهيز هذا المشهد عند دخوله الى شجرة اللعبة
func _ready() -> void:
	add_to_group("fox")
	start_pos = global_position
	_base_scale = Vector2(abs(scale.x), abs(scale.y))
	scale = _base_scale
	if move_right_first:
		dir = 1.0
	else:
		dir = -1.0
	_cache_visual_offsets()
	_setup_new_fox_frames()
	_apply_facing(not move_right_first)
	if hurt_area != null:
		hurt_area.body_entered.connect(_on_hurt_area_body_entered)

# يحدث منطق الحركة والاصطدام مع كل خطوة فيزيائية
func _physics_process(delta: float) -> void:
	_attack_pause_timer = max(_attack_pause_timer - delta, 0.0)
	_damage_cooldown_timer = max(_damage_cooldown_timer - delta, 0.0)

	if _player == null or not is_instance_valid(_player):
		var group: Array = get_tree().get_nodes_in_group("player")
		if group.size() > 0 and group[0] is Node2D:
			_player = group[0] as Node2D
		else:
			_player = null

	if _player != null and is_instance_valid(_player):
		var chase_velocity: Vector2 = _get_chase_velocity()
		var separation_velocity: Vector2 = _get_fox_separation_velocity()
		var desired_velocity: Vector2 = chase_velocity + separation_velocity
		var max_speed: float = chase_speed + min(separation_velocity.length() * 0.45, separation_strength * 0.45)
		if desired_velocity.length() > max_speed:
			desired_velocity = desired_velocity.normalized() * max_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
		_update_facing_from_velocity()
		move_and_slide()
		_animate_fox(delta)
		return

	velocity = velocity.move_toward(Vector2(dir * patrol_speed, 0.0), acceleration * delta)
	_update_facing_from_velocity()
	move_and_slide()
	_animate_fox(delta)

	var offset: float = global_position.x - start_pos.x
	if offset > patrol_distance and dir > 0.0:
		dir = -1.0
	elif offset < -patrol_distance and dir < 0.0:
		dir = 1.0

# يحدد اتجاه وجه الثعلب حسب سرعة الحركة
func _update_facing_from_velocity() -> void:
	if abs(velocity.x) > 1.0:
		_apply_facing(velocity.x < 0.0)

# يحسب سرعة مطاردة اللاعب مع تجنب الاقتراب الزائد
func _get_chase_velocity() -> Vector2:
	if _player == null:
		return Vector2.ZERO
	var to_player: Vector2 = _player.global_position - global_position
	var player_dist: float = to_player.length()
	if player_dist <= 0.001:
		return Vector2.ZERO
	var away_from_player: Vector2 = -to_player / player_dist
	if _attack_pause_timer > 0.0:
		return away_from_player * attack_recoil_speed
	if player_dist < arrival_distance:
		var push_ratio: float = 1.0 - (player_dist / arrival_distance)
		return away_from_player * separation_strength * push_ratio

	var chase_dir_to_player: Vector2 = to_player / player_dist
	var route_scale: float = clamp((player_dist - arrival_distance) / max(chase_route_release_distance, 1.0), 0.0, 1.0)
	var close_scale: float = clamp((player_dist - arrival_distance) / 180.0, 0.0, 1.0)
	var weave: float = sin(Time.get_ticks_msec() * 0.0035 + chase_weave_phase) * chase_weave_strength
	var flank_direction: Vector2 = Vector2.RIGHT.rotated(chase_flank_angle)
	if chase_flank_distance <= 0.01:
		var side_sign: float = chase_flank_side
		if abs(side_sign) <= 0.01:
			side_sign = 1.0
		flank_direction = Vector2(-chase_dir_to_player.y, chase_dir_to_player.x) * side_sign
	flank_direction = flank_direction.normalized()
	var entry_direction: Vector2 = flank_direction.rotated(PI * 0.5)
	var route_distance: float = max(chase_flank_distance, chase_route_distance)
	var flank_offset: Vector2 = flank_direction * (route_distance + weave) * route_scale
	var entry_scale: float = clamp((player_dist - arrival_distance) / max(chase_route_release_distance + 80.0, 1.0), 0.0, 1.0)
	var entry_offset: Vector2 = entry_direction * max(chase_entry_distance, chase_route_entry_distance) * entry_scale
	var lead_offset: Vector2 = chase_dir_to_player * chase_lead_distance * close_scale
	var target_position: Vector2 = _player.global_position + flank_offset + entry_offset + lead_offset
	var to_target: Vector2 = target_position - global_position
	var target_dist: float = to_target.length()
	if target_dist <= 0.001:
		return Vector2.ZERO
	var chase_dir: Vector2 = to_target / target_dist
	var chase_velocity: Vector2 = chase_dir * chase_speed
	if abs(chase_orbit_strength) > 0.01:
		var orbit_sign: float = 1.0 if chase_orbit_direction >= 0.0 else -1.0
		var orbit_tangent := Vector2(-chase_dir_to_player.y, chase_dir_to_player.x) * orbit_sign
		var orbit_ratio: float = clamp(chase_orbit_strength, 0.0, 1.0) * offset_scale
		var orbit_velocity: Vector2 = orbit_tangent * chase_speed
		chase_velocity = chase_velocity.lerp(orbit_velocity, orbit_ratio)
	return chase_velocity

# يضيف تباعدا بسيطا بين الثعالب حتى لا تتكدس
func _get_fox_separation_velocity() -> Vector2:
	var separation: Vector2 = Vector2.ZERO
	for fox in get_tree().get_nodes_in_group("fox"):
		if fox == self or not is_instance_valid(fox) or not (fox is Node2D):
			continue
		var away: Vector2 = global_position - (fox as Node2D).global_position
		var dist: float = away.length()
		if dist > 0.001 and dist < separation_distance:
			var force: float = 1.0 - (dist / separation_distance)
			separation += (away / dist) * separation_strength * force
	return separation

# يجهز صور الثعلب المتحركة اذا كان ملفها متاحا
func _setup_new_fox_frames() -> void:
	if fox_frames == null:
		return
	_fox_frames_base_position = fox_frames.position
	_fox_frames_base_scale = Vector2(abs(fox_frames.scale.x), abs(fox_frames.scale.y))
	var sprite_frames: SpriteFrames = _build_new_fox_sprite_frames()
	if sprite_frames == null:
		fox_frames.visible = false
		_set_color_rect_visuals_visible(true)
		return
	fox_frames.sprite_frames = sprite_frames
	fox_frames.visible = true
	fox_frames.play("idle")
	_use_new_fox_frames = true
	_set_color_rect_visuals_visible(false)

# يبني اطارات حركة الثعلب من لوحة الصور
func _build_new_fox_sprite_frames() -> SpriteFrames:
	if not ResourceLoader.exists(NEW_FOX_SHEET_PATH):
		push_warning("Missing fox sprite sheet: " + NEW_FOX_SHEET_PATH)
		return null
	var texture: Texture2D = load(NEW_FOX_SHEET_PATH) as Texture2D
	if texture == null:
		return null
	var cell_size: Vector2 = Vector2(float(texture.get_width()) / float(FOX_SHEET_COLUMNS), float(texture.get_height()) / float(FOX_SHEET_ROWS))
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_fox_animation(frames, texture, cell_size, "idle", 2, [0, 1, 2, 3, 4, 5, 6], 5.0, true)
	_add_fox_animation(frames, texture, cell_size, "run", 0, [0, 1, 2, 3, 4, 5, 6], 13.0, true)
	_add_fox_animation(frames, texture, cell_size, "sprint", 1, [0, 1, 2, 3, 4, 5, 6], 18.0, true)
	_add_fox_animation(frames, texture, cell_size, "stagger", 3, [0, 1, 2, 3, 2, 1], 10.0, false)
	return frames

# يضيف حركة جديدة للثعلب داخل مجموعة الاطارات
func _add_fox_animation(frames: SpriteFrames, texture: Texture2D, cell_size: Vector2, animation_name: String, row: int, columns: Array, speed: float, loop: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop)
	frames.set_animation_speed(animation_name, speed)
	for column in columns:
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(float(column) * cell_size.x, float(row) * cell_size.y, cell_size.x, cell_size.y)
		frames.add_frame(animation_name, atlas, 1.0)

# يظهر او يخفي الرسوم البسيطة البديلة للثعلب
func _set_color_rect_visuals_visible(visible_value: bool) -> void:
	for rect in _visual_rects:
		rect.visible = visible_value

# يحفظ مواقع اجزاء الثعلب حتى تتحرك مع الاتجاه الصحيح
func _cache_visual_offsets() -> void:
	var visual_names: Array[String] = [
		"Tail", "TailTip", "Sprite", "Chest", "Head", "EarLeft",
		"EarRight", "InnerEarLeft", "InnerEarRight", "Snout", "Cheek",
		"Eye", "EyeGlint", "Nose", "WhiskerTop", "WhiskerBottom",
		"LegFront", "LegBack", "PawFront", "PawBack"
	]
	for node_name in visual_names:
		var rect: ColorRect = get_node_or_null(node_name) as ColorRect
		if rect != null:
			_visual_rects.append(rect)
			_visual_offsets[rect] = [
				rect.offset_left, rect.offset_right,
				rect.offset_top, rect.offset_bottom
			]

# يعكس رسمة الثعلب حسب الاتجاه دون تغيير جسم الاصطدام
func _apply_facing(face_left: bool) -> void:

	scale = _base_scale
	if _facing_left == face_left:
		_update_frame_facing()
		return
	_facing_left = face_left
	_update_frame_facing()
	for rect in _visual_rects:
		_position_visual_rect(rect, 0.0, 0.0)

# يضبط اتجاه اطارات الثعلب المتحركة
func _update_frame_facing() -> void:
	if fox_frames == null:
		return
	var facing_sign: float = 1.0
	if _facing_left:
		facing_sign = -1.0
	fox_frames.scale = Vector2(_fox_frames_base_scale.x * facing_sign, _fox_frames_base_scale.y)

# يختار طريقة تحريك الثعلب حسب الرسوم المتاحة
func _animate_fox(delta: float) -> void:
	var speed_ratio: float = clamp(velocity.length() / max(chase_speed, 1.0), 0.0, 1.0)
	if speed_ratio <= 0.03:
		_walk_time = 0.0
	else:
		_walk_time += delta * lerp(6.0, 14.0, speed_ratio)
	if _use_new_fox_frames:
		_animate_frame_fox(speed_ratio)
	else:
		_animate_rect_fox(speed_ratio)
	_update_shadow(speed_ratio)

# يحرك ثعلب الصور المتحركة حسب السرعة
func _animate_frame_fox(speed_ratio: float) -> void:
	if fox_frames == null:
		return
	var animation_name: String = "idle"
	var animation_speed: float = 1.0
	if _attack_pause_timer > 0.0:
		animation_name = "stagger"
		animation_speed = 1.35
	elif speed_ratio > 0.68:
		animation_name = "sprint"
		animation_speed = lerp(0.9, 1.35, speed_ratio)
	elif speed_ratio > 0.03:
		animation_name = "run"
		animation_speed = lerp(0.75, 1.1, speed_ratio)
	fox_frames.speed_scale = animation_speed
	if fox_frames.animation != animation_name:
		fox_frames.play(animation_name)
	var bob: float = abs(sin(_walk_time)) * 5.0 * speed_ratio
	var lean: float = clamp(velocity.x / max(chase_speed, 1.0), -1.0, 1.0) * 0.11
	if _facing_left:
		lean *= -1.0
	fox_frames.position = _fox_frames_base_position + Vector2(0.0, -bob)
	fox_frames.rotation = lean

# يحرك شكل الثعلب البسيط عند عدم وجود صور
func _animate_rect_fox(speed_ratio: float) -> void:
	var body_bob: float = sin(_walk_time * 2.0) * 1.6 * speed_ratio
	var leg_stride: float = sin(_walk_time) * 5.0 * speed_ratio
	var tail_sway: float = sin(_walk_time * 1.35) * 2.4 * speed_ratio
	for rect in _visual_rects:
		var y_shift: float = 0.0
		var x_shift: float = 0.0
		match rect.name:
			"Sprite", "Chest", "Head", "EarLeft", "EarRight", "InnerEarLeft", "InnerEarRight", "Snout", "Cheek", "Eye", "EyeGlint", "Nose", "WhiskerTop", "WhiskerBottom":
				y_shift = body_bob
			"LegFront", "PawFront":
				x_shift = leg_stride
				y_shift = abs(leg_stride) * -0.18
			"LegBack", "PawBack":
				x_shift = -leg_stride
				y_shift = abs(leg_stride) * -0.18
			"Tail", "TailTip":
				y_shift = body_bob - tail_sway
		_position_visual_rect(rect, x_shift, y_shift)

# يحدث ظل الثعلب مع الحركة
func _update_shadow(speed_ratio: float) -> void:
	if shadow == null:
		return
	var lift: float = abs(sin(_walk_time)) * speed_ratio
	shadow.scale = Vector2(1.0 + speed_ratio * 0.10 - lift * 0.06, 1.0 - lift * 0.10)
	shadow.modulate.a = 1.0 - speed_ratio * 0.12

# يضع جزءا بصريا من الثعلب في مكانه الصحيح
func _position_visual_rect(rect: ColorRect, x_shift: float, y_shift: float) -> void:
	var offsets: Array = _visual_offsets[rect]
	var signed_x_shift: float = x_shift
	if _facing_left:
		signed_x_shift = -x_shift
	if _facing_left:
		rect.offset_left = -float(offsets[1]) + signed_x_shift
		rect.offset_right = -float(offsets[0]) + signed_x_shift
	else:
		rect.offset_left = float(offsets[0]) + signed_x_shift
		rect.offset_right = float(offsets[1]) + signed_x_shift
	rect.offset_top = float(offsets[2]) + y_shift
	rect.offset_bottom = float(offsets[3]) + y_shift

# يسبب الضرر للاعب عند دخوله منطقة هجوم الثعلب
func _on_hurt_area_body_entered(body: Node2D) -> void:
	if _damage_cooldown_timer > 0.0:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
		_damage_cooldown_timer = damage_cooldown
		_attack_pause_timer = attack_pause_duration
		var away: Vector2 = global_position - body.global_position
		if away.length() > 0.001:
			velocity = away.normalized() * attack_recoil_speed
		else:
			velocity = Vector2.RIGHT * attack_recoil_speed
