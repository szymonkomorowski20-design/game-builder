class_name OrbitCamera
extends Node3D
## Third-person orbit camera. This node follows `target` (position only) and holds the yaw; its `Pitch` child holds
## the pitch; a `SpringArm3D` under Pitch pulls the camera in front of walls. Mouse motion (while the mouse is
## captured) and an optional stick (actions camera_left/right/up/down — used only if they exist) both call `orbit()`.
## Move the player relative to the camera with `OrbitCamera.camera_relative(input, yaw)`.

@export var target: Node3D
@export var height := 1.2                ## m above the target's origin
@export var mouse_sensitivity := 0.003   ## rad per pixel of mouse motion
@export var stick_speed := 2.5           ## rad/s at full stick deflection
@export_range(-89.0, 0.0) var min_pitch_deg := -70.0   ## looking down limit
@export_range(-45.0, 45.0) var max_pitch_deg := 20.0   ## looking up limit
@export var invert_y := false
## Mouse motion only turns the camera while the mouse is captured (so menus and windowed tools still get the
## cursor). Tests and tools may switch this off.
@export var require_captured_mouse := true

var yaw := 0.0
var pitch := deg_to_rad(-25.0)

@onready var _pitch: Node3D = $Pitch


func _ready() -> void:
	orbit(0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion == null:
		return
	if require_captured_mouse and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var y_sign := 1.0 if invert_y else -1.0
	# screen_relative, not relative: `relative` is scaled by the viewport stretch (window size), so mouse-look
	# sensitivity would change with the window — measured ×10 in a headless run of this recipe.
	orbit(-motion.screen_relative.x * mouse_sensitivity, y_sign * motion.screen_relative.y * mouse_sensitivity)


func _physics_process(delta: float) -> void:
	if target != null:
		global_position = target.global_position + Vector3.UP * height
	if InputMap.has_action("camera_left"):
		var stick := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
		if stick != Vector2.ZERO:
			orbit(-stick.x * stick_speed * delta, -stick.y * stick_speed * delta)


## Turn by `d_yaw` (around up) and `d_pitch` (look up +, down −) radians; pitch is clamped, yaw wraps to −π…π.
func orbit(d_yaw: float, d_pitch: float) -> void:
	yaw = wrapf(yaw + d_yaw, -PI, PI)
	pitch = clampf(pitch + d_pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	rotation.y = yaw
	_pitch.rotation.x = pitch


## Input from `Input.get_vector(left, right, up, down)` turned into a world direction on the ground plane:
## "up" means away from the camera, whatever the camera's yaw.
static func camera_relative(input: Vector2, camera_yaw: float) -> Vector3:
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, camera_yaw)
