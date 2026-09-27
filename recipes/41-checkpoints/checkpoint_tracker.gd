class_name CheckpointTracker
extends RefCounted
## Remembers the furthest checkpoint reached. Checkpoints carry an `order`; touching an earlier one after a later
## one does not move the respawn point back. Before any checkpoint the respawn point is the start. Works for 2D and
## 3D (positions are Variants: Vector2 or Vector3). Save `active_order` with the game if checkpoints must persist.

signal activated(order: int)

var start_position: Variant
var respawn_position: Variant
var active_order := -1


func _init(start: Variant) -> void:
	start_position = start
	respawn_position = start


## A checkpoint was touched. Returns true when it became the new respawn point.
func reach(order: int, position: Variant) -> bool:
	if order <= active_order:
		return false
	active_order = order
	respawn_position = position
	activated.emit(order)
	return true


## Back to the start (a new run of the level).
func reset() -> void:
	active_order = -1
	respawn_position = start_position
