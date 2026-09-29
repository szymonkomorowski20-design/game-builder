extends Node3D
## Demo for recipe 66: flat ground for the speeds; roof A (5 m) for the edge that holds and a drop that hurts; roof B
## (10 m) above a hay pile (a soft landing); two roofs 2.5 m apart for the sprint's leap.

const STONE := Color(0.62, 0.55, 0.45)
const BLOCKS := [
	[Vector3(0, -0.5, 0), Vector3(140, 1, 140), Color(0.35, 0.38, 0.33), false],
	[Vector3(20, 2.5, 0), Vector3(6, 5, 10), STONE, false],
	[Vector3(40, 5, 0), Vector3(6, 10, 6), STONE, false],
	[Vector3(40, 0.5, -6), Vector3(5, 1, 6), Color(0.85, 0.72, 0.3), true],
	[Vector3(60, 2, 0), Vector3(6, 4, 8), STONE, false],
	[Vector3(60, 2, -10.5), Vector3(6, 4, 8), STONE, false],
]


func _ready() -> void:
	for b: Array in BLOCKS:
		var groups: Array[StringName] = []
		if b[3]:
			groups.append(&"soft_landing")
		add_child(GreyboxBlock.make(b[0], b[1], b[2], 1, groups))
