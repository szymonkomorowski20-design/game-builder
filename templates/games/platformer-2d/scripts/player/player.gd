class_name Player
extends CharacterBody2D
## Platformer player: acceleration/friction, jump defined by height + time to apex, faster fall,
## variable jump height, coyote time and jump buffering. All numbers come from `tuning`.

@export var tuning: PlayerTuning

## Observable state for tests/replays (the harness reads `state` from nodes in group gb_track).
var state: String = "idle"
var jumps_started: int = 0

var _coyote_left := 0.0
var _buffer_left := 0.0


func _physics_process(delta: float) -> void:
	var t := tuning
	var on_floor := is_on_floor()

	_coyote_left = t.coyote_time if on_floor else maxf(_coyote_left - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_buffer_left = t.jump_buffer
	else:
		_buffer_left = maxf(_buffer_left - delta, 0.0)

	if _buffer_left > 0.0 and _coyote_left > 0.0:
		velocity.y = -JumpMath.jump_velocity(t.jump_height, t.time_to_apex)
		_buffer_left = 0.0
		_coyote_left = 0.0
		jumps_started += 1

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= t.jump_cut_multiplier

	# Gravity in two halves around the move — AFTER the jump impulse, so every frame moves with the
	# frame's average velocity (exact for constant acceleration). Adding the whole step before moving,
	# or the first half before the impulse, overshoots the designed height by ~v0·dt/2
	# (75 px instead of 72 at 60 Hz — caught by scenario p2_jump_height).
	velocity.y = minf(velocity.y + _gravity() * delta * 0.5, t.max_fall_speed)

	var dir := Input.get_axis("move_left", "move_right")
	var rate := t.acceleration if not is_zero_approx(dir) else t.friction
	if not on_floor:
		rate *= t.air_control
	velocity.x = move_toward(velocity.x, dir * t.run_speed, rate * delta)

	move_and_slide()
	if not is_on_floor():
		velocity.y = minf(velocity.y + _gravity() * delta * 0.5, t.max_fall_speed)
	_update_state()


func _gravity() -> float:
	var g := JumpMath.gravity(tuning.jump_height, tuning.time_to_apex)
	return g * tuning.fall_gravity_multiplier if velocity.y > 0.0 else g


func _update_state() -> void:
	if not is_on_floor():
		state = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 1.0:
		state = "run"
	else:
		state = "idle"


## Put the player somewhere at rest (respawn, tests).
func teleport(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_coyote_left = 0.0
	_buffer_left = 0.0
