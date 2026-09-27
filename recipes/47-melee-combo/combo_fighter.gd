extends CharacterBody3D
## Demo fighter: walks on the ground plane (move_* actions, world axes), turns to face where it walks, and slows to
## ComboMelee3D.move_scale() while swinging.

@export var speed := 5.0

@onready var melee := $Melee as ComboMelee3D


func _physics_process(_delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var dir := Vector3(input.x, 0.0, input.y)
	velocity = dir * speed * melee.move_scale()
	if dir.length() > 0.1 and melee.combo.phase == ComboAttack.Phase.IDLE:
		look_at(global_position + dir, Vector3.UP)
	move_and_slide()
