class_name RunState
extends RefCounted
## One attempt: its seed, how deep it got, the path taken and the meta currency picked up along the way.
## end(won) returns what goes to MetaProgress.bank() — all of it, even on death, so every run moves the player on.

var seed := 0
var depth := 0
var collected := 0
var path: Array[RoomDoor.Type] = []
var over := false


func begin(run_seed: int) -> void:
	seed = run_seed
	depth = 0
	collected = 0
	path.clear()
	over = false


func enter(door: RoomDoor) -> void:
	path.append(door.type)
	depth += 1


func previous_type() -> RoomDoor.Type:
	return path.back() if not path.is_empty() else RoomDoor.Type.COMBAT


func collect(amount: int) -> void:
	collected += amount


func end(_won: bool) -> int:
	over = true
	return collected
