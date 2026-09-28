class_name RtsProduction
extends RefCounted
## One building's production queue (recipe 60). An item is {id, cost, supply, time}.
## - Queuing pays the cost at once (so the stockpile shows it), up to `max_queue` items; a cancel refunds it in full.
## - The front item reserves its supply when it starts. When it does not fit, the building waits ("supply blocked":
##   `blocked` fires once, the HUD says "build more farms") and starts as soon as it fits.
## - A finished item emits `produced(id)`; the host spawns the unit at the building and sends it to `rally_point`.
## `tick(delta)` runs the clock; a paused game simply stops calling it.

signal produced(id: StringName)
signal blocked(id: StringName)
signal changed

var max_queue := 5
var rally_point := Vector3.INF
var stockpile: RtsStockpile
var queue: Array[Dictionary] = []     ## {id, cost, supply, time}
var progress := 0.0                   ## seconds into the front item
var started := false                  ## the front item has its supply

var _blocked_said := false


static func item(id: StringName, cost: Dictionary, supply: int, time: float) -> Dictionary:
	return {"id": id, "cost": cost, "supply": supply, "time": time}


## Adds an item. False when the queue is full or it can't be paid for (nothing is taken then).
func enqueue(it: Dictionary) -> bool:
	if queue.size() >= max_queue or stockpile == null or not stockpile.spend(it.cost):
		return false
	queue.append(it)
	changed.emit()
	return true


## Cancels item `index` (the last by default): the cost back in full, and its supply if it had started.
func cancel(index: int = -1) -> bool:
	if queue.is_empty():
		return false
	var i := index if index >= 0 else queue.size() - 1
	if i >= queue.size():
		return false
	var it: Dictionary = queue[i]
	stockpile.refund(it.cost)
	if i == 0:
		if started:
			stockpile.release(int(it.supply))
		started = false
		progress = 0.0
		_blocked_said = false
	queue.remove_at(i)
	changed.emit()
	return true


func tick(delta: float) -> void:
	if queue.is_empty():
		return
	var it: Dictionary = queue[0]
	if not started:
		if not stockpile.reserve(int(it.supply)):
			if not _blocked_said:
				_blocked_said = true
				blocked.emit(it.id)
			return
		started = true
		_blocked_said = false
	progress += delta
	if progress >= float(it.time):
		queue.pop_front()
		progress = 0.0
		started = false
		produced.emit(it.id)
		changed.emit()


## 0–1 of the front item (the button's fill).
func fraction() -> float:
	if queue.is_empty():
		return 0.0
	return clampf(progress / maxf(float(queue[0].time), 0.001), 0.0, 1.0)


## The front item waits for supply.
func is_blocked() -> bool:
	return not queue.is_empty() and not started and _blocked_said
