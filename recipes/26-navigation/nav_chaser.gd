class_name NavChaser
extends CharacterBody2D
## Follows a NavigationAgent2D path around obstacles. go_to(point) sets the target; the path is recomputed by the
## agent when the target moves more than its `target_desired_distance`.

@export var speed := 150.0

@onready var agent: NavigationAgent2D = $Agent

var max_y := -INF   ## for the test: proves the chaser went through the gap under the wall


func go_to(point: Vector2) -> void:
	agent.target_position = point


## True once the navigation map can answer a path query to `point`. Measured on 4.7.2: the map's first
## iteration (id 1) exists at frame 0 but is EMPTY; the region's polygons arrive a few frames later (async
## region updates since 4.5). Waiting a fixed number of frames is a race — wait for this instead.
func map_ready(point: Vector2) -> bool:
	var map := agent.get_navigation_map()
	return NavigationServer2D.map_get_iteration_id(map) > 0 \
		and not NavigationServer2D.map_get_path(map, global_position, point, true).is_empty()


func _physics_process(_delta: float) -> void:
	max_y = maxf(max_y, global_position.y)
	if agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	var next := agent.get_next_path_position()
	velocity = global_position.direction_to(next) * speed
	move_and_slide()
