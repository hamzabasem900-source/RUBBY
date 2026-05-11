extends CharacterBody2D

# =============================================
# Player — Bunny Controller
# Controls: WASD / Arrow keys to move
#           Space / Enter  to DASH (short speed burst, 1.2 s cooldown)
# =============================================

const SPEED:             float = 190.0
const DASH_SPEED:        float = 460.0
const DASH_DURATION:     float = 0.16
const DASH_COOLDOWN:     float = 1.2
const INVINCIBLE_DURATION: float = 1.5

var invincible:      bool  = false
var invincible_timer: float = 0.0

var _dashing:       bool   = false
var _dash_timer:    float  = 0.0
var _dash_cooldown: float  = 0.0
var _dash_dir:      Vector2 = Vector2.RIGHT

var character_colors: Dictionary = {
	"white_bunny": Color(0.95, 0.95, 0.95),
	"brown_bunny": Color(0.60, 0.35, 0.10)
}

@onready var sprite:  ColorRect = $Sprite
@onready var ear_l:   ColorRect = $EarLeft
@onready var ear_r:   ColorRect = $EarRight
@onready var tail:    ColorRect = $Tail
@onready var pickup:  Area2D    = $PickupArea

func _ready() -> void:
	add_to_group("player")
	# Apply selected character colour
	var col: Color = character_colors.get(
		GameManager.selected_character, Color(0.95, 0.95, 0.95)
	)
	if sprite: sprite.color = col
	if ear_l:  ear_l.color  = col
	if ear_r:  ear_r.color  = col
	if tail:   tail.color   = Color(col.r * 0.88, col.g * 0.88, col.b * 0.88)
	# Connect pickup area for carrot detection
	if pickup:
		pickup.area_entered.connect(_on_pickup_area_entered)

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
		dir      = dir.normalized()
		scale.x  = -1.0 if dir.x < 0 else 1.0
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
		GameManager.add_score(points)
		if points >= 25:
			AudioManager.play_golden_collect()
		else:
			AudioManager.play_collect()
		area.collect()
