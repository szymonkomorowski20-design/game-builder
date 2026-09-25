class_name TopDownMover
extends CharacterBody2D
## 8-direction top-down movement with acceleration and friction. `Input.get_vector` already caps the
## input length at 1, so diagonals are NOT faster than straight lines (the classic bug with
## `Vector2(x, y) * speed` built from two axes).

@export var speed: float = 160.0          ## px/s
@export var acceleration: float = 1200.0  ## px/s² toward the target velocity
@export var friction: float = 1400.0      ## px/s² toward zero when there is no input


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var rate := acceleration if dir != Vector2.ZERO else friction
	velocity = velocity.move_toward(dir * speed, rate * delta)
	move_and_slide()
