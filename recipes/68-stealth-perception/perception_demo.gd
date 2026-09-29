extends Node3D
## Demo for recipe 68: guard A at the origin looks along −Z; a wall to hide behind at (−5, −8). Guard B at x = 30 has a
## 20 m wall 2.5 m behind it, for hearing along paths. The navigation mesh is baked on load (synchronously, so a
## scenario plays the same every run).

const GROUND := Color(0.35, 0.38, 0.33)
const WALL := Color(0.55, 0.5, 0.45)

@onready var nav: NavigationRegion3D = $Navigation


func _ready() -> void:
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.agent_radius = 0.5
	nm.agent_height = 1.75
	nm.agent_max_climb = 0.25
	nav.navigation_mesh = nm
	nav.add_child(GreyboxBlock.make(Vector3(10, -0.5, 0), Vector3(90, 1, 60), GROUND))
	nav.add_child(GreyboxBlock.make(Vector3(-5, 1.5, -8), Vector3(6, 3, 0.4), WALL))
	nav.add_child(GreyboxBlock.make(Vector3(30, 1.5, 2.5), Vector3(20, 3, 0.4), WALL))
	nav.bake_navigation_mesh(false)
