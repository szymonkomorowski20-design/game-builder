extends Node3D
## Demo for recipe 67: a 6 m building whose face (z = 0, facing +Z) carries lips at 2.2, 3.4 and 4.6 m (the 3.4 one
## has a 1.2 m gap for the side jump); a 1.1 m crate to step onto; a 1 m fence to vault.

const STONE := Color(0.62, 0.55, 0.45)
const HOLD := Color(0.86, 0.8, 0.66)    # holds share one lighter colour: climbable things must read (genre doc §12)


func _ready() -> void:
	add_child(GreyboxBlock.make(Vector3(0, -0.5, 0), Vector3(80, 1, 80), Color(0.35, 0.38, 0.33)))
	add_child(GreyboxBlock.make(Vector3(0, 3, -3), Vector3(8, 6, 6), STONE))
	for lip: Array in lips():
		add_child(GreyboxBlock.make(lip[0], lip[1], HOLD))
	add_child(GreyboxBlock.make(Vector3(9, 0.55, 3), Vector3(1.5, 1.1, 1.5), HOLD))
	add_child(GreyboxBlock.make(Vector3(-9, 0.5, 3), Vector3(3, 1.0, 0.2), HOLD))
	# A wall with a knee-high lip under a real hold: the grab must skip the low one.
	add_child(GreyboxBlock.make(Vector3(16, 2, -1.5), Vector3(4, 4, 3), STONE))
	for top: float in [0.9, 2.2]:
		add_child(GreyboxBlock.make(Vector3(16, top - 0.075, 0.06), Vector3(4, 0.15, 0.12), HOLD))


## [centre, size] of each lip: 0.15 m thick, sticking 0.12 m out of the face.
static func lips() -> Array:
	var out := []
	for seg: Array in [[2.2, -4.0, 4.0], [3.4, -4.0, 0.0], [3.4, 1.2, 4.0], [4.6, -4.0, 4.0]]:
		var top: float = seg[0]
		var x0: float = seg[1]
		var x1: float = seg[2]
		out.append([Vector3((x0 + x1) * 0.5, top - 0.075, 0.06), Vector3(x1 - x0, 0.15, 0.12)])
	return out
