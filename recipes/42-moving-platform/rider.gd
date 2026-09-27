class_name PlatformRider
extends CharacterBody2D
## Demo rider: gravity only, no input — it should travel with the platform it stands on.

@export var gravity := 900.0   ## px/s²


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	velocity.x = 0.0
	move_and_slide()
