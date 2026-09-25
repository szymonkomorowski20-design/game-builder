extends CharacterBody2D

const SPEED := 120.0
const JUMP := -300.0
const GRAVITY := 900.0

var score: int = 0


func _physics_process(delta: float) -> void:
	velocity.x = Input.get_axis("move_left", "move_right") * SPEED
	velocity.y += GRAVITY * delta
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP
		score += 1
	move_and_slide()
