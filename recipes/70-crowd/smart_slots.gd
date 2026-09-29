class_name SmartSlots
extends RefCounted
## A bench, a stall, a well: a place with a few slots that holds everything about its use (genre doc §7, smart
## objects). A slot is free, then reserved by someone walking to it, then occupied; a reserved slot isn't taken by
## anyone else until it is released. A bench with its two seats taken is a hiding place for a third person (genre doc
## §6): `full()`.

var positions: Array[Vector3] = []
var _holder: Array[int] = []
var _sitting: Array[bool] = []


func _init(slot_positions: Array[Vector3] = []) -> void:
	for p in slot_positions:
		positions.append(p)
		_holder.append(0)
		_sitting.append(false)


## The index of a free slot now reserved for `who` (the nearest to `from`), or -1. Asking again returns the same slot.
func reserve(who: Object, from: Vector3 = Vector3.ZERO) -> int:
	var id := who.get_instance_id()
	var mine := _holder.find(id)
	if mine >= 0:
		return mine
	var best := -1
	for i in positions.size():
		if _holder[i] == 0 and (best < 0 or positions[i].distance_to(from) < positions[best].distance_to(from)):
			best = i
	if best >= 0:
		_holder[best] = id
	return best


## The holder arrived: its reserved slot is now occupied.
func occupy(who: Object) -> bool:
	var i := _holder.find(who.get_instance_id())
	if i < 0:
		return false
	_sitting[i] = true
	return true


func release(who: Object) -> void:
	var i := _holder.find(who.get_instance_id())
	if i >= 0:
		_holder[i] = 0
		_sitting[i] = false


func occupied() -> int:
	return _sitting.count(true)


func full() -> bool:
	return positions.size() > 0 and occupied() == positions.size()
