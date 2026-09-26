class_name NavChaser
extends CharacterBody2D
## Follows a NavigationAgent2D path around obstacles. go_to(point) sets the target; the path is recomputed by the
## agent when the target moves more than its `target_desired_distance`.

@export var speed := 150.0

@onready var agent: NavigationAgent2D = $Agent

var max_y := -INF   ## for the test: proves the chaser went through the gap under the wall


func go_to(point: Vector2) -> void:
	agent.target_position = point


func _physics_process(_delta: float) -> void:
	max_y = maxf(max_y, global_position.y)
	if agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	var next := agent.get_next_path_position()
	velocity = global_position.direction_to(next) * speed
	move_and_slide()
