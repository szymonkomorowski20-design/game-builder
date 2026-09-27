class_name Player
extends CharacterBody3D
## 3D platformer player: acceleration/friction on the ground plane (move_up = away from the camera, -Z), jump defined
## by height + time to apex, faster fall, variable jump height, coyote time and jump buffering; the body turns toward
## the movement. The chase camera (CameraRig/SpringArm) follows at a fixed angle and shortens against walls.
## All numbers come from `tuning`.

@export var tuning: PlayerTuning

## Observable state for tests/replays (the harness reads `state` from nodes in group gb_track).
var state: String = "idle"
var jumps_started: int = 0

var _coyote_left := 0.0
var _buffer_left := 0.0

@onready var body: Node3D = $Body
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm


func _physics_process(delta: float) -> void:
	var t := tuning
	var on_floor := is_on_floor()

	_coyote_left = t.coyote_time if on_floor else maxf(_coyote_left - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_buffer_left = t.jump_buffer
	else:
		_buffer_left = maxf(_buffer_left - delta, 0.0)

	if _buffer_left > 0.0 and _coyote_left > 0.0:
		velocity.y = JumpMath.jump_velocity(t.jump_height, t.time_to_apex)
		_buffer_left = 0.0
		_coyote_left = 0.0
		jumps_started += 1

	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= t.jump_cut_multiplier

	# Gravity in two halves around the move (exact for constant acceleration) — see the 2D template's P2 note.
	velocity.y = maxf(velocity.y - _gravity() * delta * 0.5, -t.max_fall_speed)

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := Vector3(input.x, 0.0, input.y)
	var rate := t.acceleration if dir != Vector3.ZERO else t.friction
	if not on_floor:
		rate *= t.air_control
	var planar := Vector3(velocity.x, 0.0, velocity.z).move_toward(dir * t.run_speed, rate * delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if dir != Vector3.ZERO:
		body.rotation.y = rotate_toward(body.rotation.y, atan2(-dir.x, -dir.z), t.turn_speed * delta)

	move_and_slide()
	if not is_on_floor():
		velocity.y = maxf(velocity.y - _gravity() * delta * 0.5, -t.max_fall_speed)
	_update_state()


func _gravity() -> float:
	var g := JumpMath.gravity(tuning.jump_height, tuning.time_to_apex)
	return g * tuning.fall_gravity_multiplier if velocity.y < 0.0 else g


func _update_state() -> void:
	if not is_on_floor():
		state = "jump" if velocity.y > 0.0 else "fall"
	elif Vector2(velocity.x, velocity.z).length() > 0.05:
		state = "run"
	else:
		state = "idle"


## Put the player somewhere at rest (respawn, tests).
func teleport(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_coyote_left = 0.0
	_buffer_left = 0.0
