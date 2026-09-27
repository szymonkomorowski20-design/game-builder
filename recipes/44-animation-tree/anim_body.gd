class_name AnimBody
extends CharacterBody2D
## Demo body: run and jump with gravity — just enough movement for the animator to react to.

@export var speed := 160.0
@export var jump_speed := 380.0
@export var gravity := 1000.0


func _physics_process(delta: float) -> void:
	velocity.x = Input.get_axis("move_left", "move_right") * speed
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = -jump_speed
	elif not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()
