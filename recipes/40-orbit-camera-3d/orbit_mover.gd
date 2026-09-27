class_name OrbitMover
extends CharacterBody3D
## Demo body for the orbit camera: moves relative to the camera's yaw, with gravity. Your player replaces it.

@export var camera: OrbitCamera
@export var speed := 5.0      ## m/s
@export var gravity := 20.0   ## m/s²


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := OrbitCamera.camera_relative(input, camera.yaw)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta
	move_and_slide()
