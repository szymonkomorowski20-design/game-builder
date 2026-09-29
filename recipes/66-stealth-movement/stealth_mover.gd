class_name StealthMover
extends CharacterBody3D
## A third-person body for stealth and parkour (recipe 66): camera-relative movement at MoveProfiles speeds, turning
## toward the movement, a jump with a buffer and coyote time, an EdgeGuard at roof edges and a FallRule on landing. It
## reports noise for guards (recipe 68) through `noise_made`, step by step and on landing. While `climbing` is true
## another system owns the body (the climber of recipe 67) and this script does nothing.
##
## Input actions: move_left/right/up/down and jump; sprint, sneak and drop are optional (used only if they exist).
## `drop` is the "down" intent: walk off an edge on purpose.

signal noise_made(at: Vector3, radius: float)
signal landed(height: float, outcome: Dictionary)
signal stopped_at_edge

## A node whose global yaw turns the input (the orbit camera of recipe 40). Empty: world axes, "up" = −Z.
@export var camera_path: NodePath
@export var acceleration := 30.0       ## m/s² toward the wished velocity
@export var friction := 40.0           ## m/s² toward rest when there is no input
@export var air_control := 0.3         ## share of acceleration in the air
@export var turn_speed := 12.0         ## rad/s the Body child turns toward the movement
@export var jump_height := 1.2         ## m
@export var jump_time_to_apex := 0.38  ## s
@export var fall_gravity_scale := 1.6  ## heavier on the way down
@export var max_fall_speed := 40.0
@export var coyote_time := 0.1         ## s a jump still works after leaving a floor
@export var jump_buffer := 0.12        ## s a jump press is remembered before landing
@export var drop_window := 0.35        ## s a drop press lets the body walk off an edge
@export var step_length := 0.9         ## m between footstep noises
@export var step_down_max := 0.6       ## drops up to this are steps, not edges
@export var edge_probe_ahead := 0.45   ## m ahead of the feet the edge probe looks down
@export var auto_jump_when_sprinting := true
@export_flags_3d_physics var world_mask := 1

var profiles := MoveProfiles.new()
var fall_rule := FallRule.new()
var profile: StringName = MoveProfiles.WALK
var climbing := false
## Observable for tests and replays: idle / move / air / edge.
var state := "idle"
var last_landing: Dictionary = {}
var jumps := 0
## Set by the game: standing in darkness, blended into a crowd (recipe 70). Guards read them (recipe 68).
var in_shadow := false
var blended := false

var _coyote := 0.0
var _buffer := 0.0
var _drop := 0.0
var _peak_y := 0.0
var _step_travel := 0.0
var _body: Node3D


func _ready() -> void:
	_body = get_node_or_null("Body") as Node3D
	_peak_y = global_position.y


func _physics_process(delta: float) -> void:
	if climbing:
		_peak_y = global_position.y
		return
	var on_floor := is_on_floor()
	_coyote = coyote_time if on_floor else maxf(_coyote - delta, 0.0)
	_buffer = jump_buffer if _just("jump") else maxf(_buffer - delta, 0.0)
	_drop = drop_window if _just("drop") else maxf(_drop - delta, 0.0)

	var input := _input_vector()
	var stick := minf(input.length(), 1.0)
	profile = profiles.pick(stick, _held("sprint"), _held("sneak"))
	var dir := wish_direction(input)
	var wished := dir * profiles.speed(profile) if stick > 0.01 else Vector3.ZERO

	var at_edge := false
	if on_floor and wished != Vector3.ZERO:
		var exclude: Array[RID] = [get_rid()]
		var drop := EdgeGuard.probe_drop(get_world_3d().direct_space_state, global_position, dir,
				edge_probe_ahead, step_down_max + 0.05, world_mask, exclude)
		match EdgeGuard.decide(drop, step_down_max, _buffer > 0.0, _drop > 0.0,
				profile == MoveProfiles.SPRINT, auto_jump_when_sprinting):
			EdgeGuard.STOP:
				at_edge = true
			EdgeGuard.JUMP:
				_buffer = maxf(_buffer, delta)   # jump now, even without a press (the sprint's leap)

	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = 2.0 * jump_height / jump_time_to_apex
		_buffer = 0.0
		_coyote = 0.0
		jumps += 1
	velocity.y = maxf(velocity.y - _gravity() * delta, -max_fall_speed)

	var planar := Vector3(velocity.x, 0.0, velocity.z)
	if at_edge:
		planar = Vector3.ZERO
		if state != "edge":
			stopped_at_edge.emit()
	else:
		var rate := acceleration if wished != Vector3.ZERO else friction
		if not on_floor:
			rate *= air_control
		planar = planar.move_toward(wished, rate * delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if _body != null and dir != Vector3.ZERO:
		_body.rotation.y = rotate_toward(_body.rotation.y, atan2(-dir.x, -dir.z), turn_speed * delta)

	move_and_slide()
	_after_move(delta, at_edge)


## Input from the move actions as a world direction on the ground plane, turned by the camera's yaw.
func wish_direction(input: Vector2) -> Vector3:
	var d := Vector3(input.x, 0.0, input.y)
	if d.length_squared() < 1e-6:
		return Vector3.ZERO
	var cam := get_node_or_null(camera_path) as Node3D
	if cam != null:
		d = d.rotated(Vector3.UP, cam.global_rotation.y)
	return d.normalized()


## What a guard's senses (recipe 68) read about this body: how it moves and where it stands.
func stealth_cues() -> Dictionary:
	var speed := Vector2(velocity.x, velocity.z).length()
	return {
		sneaking = profile == MoveProfiles.SNEAK and not climbing,
		high_profile = climbing or (profiles.is_high_profile(profile) and speed > 0.1),
		still = speed < 0.1 and not climbing,
		shadow = in_shadow,
		blended = blended,
	}


## Put the body somewhere at rest (respawn, tests, the end of a climb).
func teleport(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_peak_y = pos.y
	_coyote = 0.0
	_buffer = 0.0


func _after_move(delta: float, at_edge: bool) -> void:
	if not is_on_floor():
		_peak_y = maxf(_peak_y, global_position.y)
		state = "air"
		return
	if state == "air":
		_land()
	_peak_y = global_position.y
	var speed := Vector2(velocity.x, velocity.z).length()
	state = "edge" if at_edge else ("move" if speed > 0.1 else "idle")
	_step_travel += speed * delta
	if _step_travel >= step_length:
		_step_travel = 0.0
		var r := profiles.noise(profile)
		if r > 0.0:
			noise_made.emit(global_position, r)


func _land() -> void:
	var height := _peak_y - global_position.y
	var soft := _on_soft_floor()
	last_landing = fall_rule.outcome(height, soft)
	last_landing.height = height
	last_landing.soft = soft
	landed.emit(height, last_landing)
	var r := profiles.landing_noise(height) * (0.25 if soft else 1.0)
	if r > 0.0:
		noise_made.emit(global_position, r)


func _on_soft_floor() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var n := c.get_normal()
		var hit := c.get_collider() as Node
		if n.y > 0.7 and hit != null and hit.is_in_group(&"soft_landing"):
			return true
	return false


func _gravity() -> float:
	var g := 2.0 * jump_height / (jump_time_to_apex * jump_time_to_apex)
	return g * fall_gravity_scale if velocity.y < 0.0 else g


func _input_vector() -> Vector2:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		if not InputMap.has_action(a):
			return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _held(action: StringName) -> bool:
	return InputMap.has_action(action) and Input.is_action_pressed(action)


func _just(action: StringName) -> bool:
	return InputMap.has_action(action) and Input.is_action_just_pressed(action)
