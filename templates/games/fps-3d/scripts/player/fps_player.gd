class_name FpsPlayer
extends CharacterBody3D
## First-person player. Yaw on this body, pitch on `Head`; mouse look reads `screen_relative` (not `relative`, which
## the viewport stretch scales — see godot-pitfalls) while the mouse is captured, the right stick uses look_* actions.
## Movement is relative to the yaw; jump from height + time to apex. The weapon under the camera does the shooting.

@export var tuning: FpsTuning
## Mouse look only while the mouse is captured (menus keep the cursor). Tests switch this off.
@export var require_captured_mouse := true

var yaw := 0.0
var pitch := 0.0
var jumps := 0

@onready var head: Node3D = $Head
@onready var weapon: Weapon = $Head/Camera/Weapon


func _ready() -> void:
	look(0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion == null:
		return
	if require_captured_mouse and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	look(-motion.screen_relative.x * tuning.mouse_sensitivity, -motion.screen_relative.y * tuning.mouse_sensitivity)


func _physics_process(delta: float) -> void:
	var t := tuning
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick != Vector2.ZERO:
		look(-stick.x * t.stick_look_speed * delta, -stick.y * t.stick_look_speed * delta)

	var g := JumpMath.gravity(t.jump_height, t.time_to_apex)
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JumpMath.jump_velocity(t.jump_height, t.time_to_apex)
			jumps += 1
	else:
		velocity.y -= g * delta

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw)
	var rate := t.acceleration if dir != Vector3.ZERO else t.friction
	if not is_on_floor():
		rate *= t.air_control
	var planar := Vector3(velocity.x, 0.0, velocity.z).move_toward(dir * t.walk_speed, rate * delta)
	velocity.x = planar.x
	velocity.z = planar.z
	move_and_slide()

	if Input.is_action_pressed("shoot"):
		weapon.try_fire()


## Turn by d_yaw (left +) and d_pitch (up +) radians; pitch is clamped.
func look(d_yaw: float, d_pitch: float) -> void:
	yaw = wrapf(yaw + d_yaw, -PI, PI)
	pitch = clampf(pitch + d_pitch, deg_to_rad(tuning.min_pitch_deg), deg_to_rad(tuning.max_pitch_deg))
	rotation.y = yaw
	head.rotation.x = pitch


## Point the view at a world position (tests, cut-scenes, aim assist).
func aim_at(point: Vector3) -> void:
	var from := head.global_position
	var to := point - from
	yaw = atan2(-to.x, -to.z)
	pitch = 0.0
	look(0.0, atan2(to.y, Vector2(to.x, to.z).length()))
