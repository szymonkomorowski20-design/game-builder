class_name RtsResourceNode
extends RefCounted
## A resource node (recipe 59): a gold mine, a tree, a crystal. It holds `amount`, and at most `max_gatherers` workers
## gather at it at once — the rest wait their turn. That limit is the saturation the genre is built on: a third worker
## on a patch that takes two adds almost nothing, so the player expands instead of stacking workers.

signal depleted

var kind: StringName = &"gold"
var amount := 1000
var max_gatherers := 2
var position := Vector3.ZERO
var gathering: Array[Object] = []


func _init(k: StringName = &"gold", start: int = 1000, slots: int = 2, at: Vector3 = Vector3.ZERO) -> void:
	kind = k
	amount = start
	max_gatherers = slots
	position = at


func is_spent() -> bool:
	return amount <= 0


## A worker at the node asks for a slot. True when it may gather now (or already does).
func try_occupy(worker: Object) -> bool:
	if is_spent():
		return false
	if gathering.has(worker):
		return true
	gathering = gathering.filter(func(w: Variant) -> bool: return is_instance_valid(w))   # a dead worker frees its slot
	if gathering.size() >= max_gatherers:
		return false
	gathering.append(worker)
	return true


func release(worker: Object) -> void:
	gathering.erase(worker)


## Takes up to `n` (the worker's load). Returns what it got.
func take(n: int) -> int:
	var got := mini(n, amount)
	amount -= got
	if got > 0 and amount <= 0:
		depleted.emit()
	return got


## Expected income per minute for `workers` on one node (the balance sheet's number): each worker's trip is
## 2 × distance / speed + gather_time and brings `carry`; the node's slots cap it at max_gatherers × carry / gather_time.
static func income_per_minute(workers: int, distance: float, speed: float, gather_time: float, carry: int, slots: int) -> float:
	if workers <= 0:
		return 0.0
	var trip := 2.0 * distance / maxf(speed, 0.01) + gather_time
	var free_flow := workers * carry / trip
	var slot_cap := slots * carry / maxf(gather_time, 0.01)
	return minf(free_flow, slot_cap) * 60.0
