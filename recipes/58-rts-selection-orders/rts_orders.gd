class_name RtsOrders
extends RefCounted
## RTS orders (recipe 58): one unit's queue of orders — move, attack, attack-move, stop, hold, gather, build, patrol —
## and the "smart" right-click that picks the order from what was clicked. Shift appends to the queue instead of
## replacing it. The unit's body reads `current()` and calls `done()` when the order is finished.
##
## Smart order (the genre's right-click), for a unit of team `team`:
##   an enemy (or its building)            → ATTACK it;
##   a resource, and the unit can gather   → GATHER it;
##   an own unfinished building, can build → BUILD (help build / repair) it;
##   anything else                         → MOVE to the ground point.
## A target is any Object with `team: int` (resources and neutrals use -1), and optionally `is_resource: bool`,
## `finished: bool` (buildings), `alive: bool`.

signal order_changed(order: Dictionary)

enum Kind { MOVE, ATTACK, ATTACK_MOVE, STOP, HOLD, GATHER, BUILD, PATROL }

const MAX_QUEUE := 16                 ## shift-queued orders kept (older games: fewer; players rarely need more)

var queue: Array[Dictionary] = []     ## {kind: Kind, at: Vector3, target: Object}


static func make(kind: Kind, at: Vector3 = Vector3.ZERO, target: Object = null) -> Dictionary:
	return {"kind": kind, "at": at, "target": target}


## The right-click order for this unit: see the table above.
static func smart(team: int, can_gather: bool, can_build: bool, target: Object, ground: Vector3) -> Dictionary:
	if target != null and is_instance_valid(target) and _alive(target):
		var t := int(target.get(&"team"))
		if bool(target.get(&"is_resource")):
			if can_gather:
				return make(Kind.GATHER, ground, target)
		elif t >= 0 and t != team:
			return make(Kind.ATTACK, ground, target)
		elif t == team and can_build and target.get(&"finished") != null and not bool(target.get(&"finished")):
			return make(Kind.BUILD, ground, target)
	return make(Kind.MOVE, ground)


## A new order: replaces the queue, or (shift) joins its end. STOP and HOLD always replace.
func give(order: Dictionary, shift: bool = false) -> void:
	var k: Kind = order.kind
	if not shift or k == Kind.STOP or k == Kind.HOLD or queue.is_empty():
		queue = [order]
	elif queue.size() < MAX_QUEUE:
		queue.append(order)
	order_changed.emit(current())


## The order being carried out ({} when idle).
func current() -> Dictionary:
	_drop_dead_targets()
	return {} if queue.is_empty() else queue[0]


## The current order is finished: the next one starts. A PATROL goes to the back of the queue (back and forth).
func done() -> void:
	if queue.is_empty():
		return
	var o: Dictionary = queue.pop_front()
	if o.kind == Kind.PATROL:
		queue.append(o)
	order_changed.emit(current())


func clear() -> void:
	queue.clear()
	order_changed.emit({})


func idle() -> bool:
	return current().is_empty()


## An ATTACK whose target died is over; so is a GATHER on a spent resource and a BUILD on a finished building.
func _drop_dead_targets() -> void:
	while not queue.is_empty():
		var o: Dictionary = queue[0]
		var t: Object = o.target
		var over := false
		if o.kind == Kind.ATTACK or o.kind == Kind.GATHER:
			over = t == null or not is_instance_valid(t) or not _alive(t)
		elif o.kind == Kind.BUILD:
			over = t == null or not is_instance_valid(t) or bool(t.get(&"finished"))
		if not over:
			return
		queue.pop_front()
		order_changed.emit({} if queue.is_empty() else queue[0])


static func _alive(c: Object) -> bool:
	var a = c.get(&"alive")
	return a == null or bool(a)
