class_name RtsGatherer
extends RefCounted
## A worker's gathering loop (recipe 59), as logic: TO_NODE → (WAIT for a slot) → GATHERING → TO_DROP → deposit →
## TO_NODE … The body walks to `target()` and calls `tick(delta, arrived)`; nothing here moves anything.
## - A spent node sends the worker to the next one (`find_node`, the game's nearest node of that kind), or idle.
## - The drop-off is the nearest one when the load is ready (`find_drop`), so a new town hall near the mine is used at
##   once.
## - A worker ordered away mid-gather (`stop()`) keeps its load and gives up its slot.
## - A worker that waits longer than `max_wait` for a slot asks `find_node(kind, from, busy)` for another node (the
##   game should prefer nodes with free slots and skip `busy`); with none, it keeps waiting.

signal deposited(kind: StringName, amount: int)

enum State { IDLE, TO_NODE, WAIT, GATHERING, TO_DROP }

var state := State.IDLE
var node: RtsResourceNode
var carrying := 0
var carrying_kind: StringName = &""
var gather_time := 1.5             ## s at the node per load
var carry := 10                    ## a load
var max_wait := 2.0                ## s waiting for a slot before trying another node
var stockpile: RtsStockpile
var find_node: Callable            ## (kind: StringName, from: Vector3, busy: RtsResourceNode) -> RtsResourceNode or null
var find_drop: Callable            ## (from: Vector3) -> Vector3 (Vector3.INF: no drop-off)
var position := Vector3.ZERO       ## the body's position, set by the host every tick

var _drop := Vector3.INF
var _gathered := 0.0
var _waited := 0.0


## Start gathering at `n` (a right-click on a resource).
func gather(n: RtsResourceNode) -> void:
	_leave_slot()
	node = n
	state = State.TO_NODE if carrying == 0 or carrying_kind == n.kind else State.TO_DROP
	if state == State.TO_DROP:
		_drop = _nearest_drop()


## Where the body should walk now (Vector3.INF: stay).
func target() -> Vector3:
	match state:
		State.TO_NODE, State.WAIT, State.GATHERING:
			return node.position if node != null else Vector3.INF
		State.TO_DROP:
			return _drop
	return Vector3.INF


## Another order: the slot is given up; the load stays (it is delivered with the next gather).
func stop() -> void:
	_leave_slot()
	state = State.IDLE


func tick(delta: float, arrived: bool) -> void:
	match state:
		State.TO_NODE, State.WAIT:
			if node == null or node.is_spent():
				_next_node()
			elif arrived:
				if node.try_occupy(self):
					state = State.GATHERING
					_gathered = 0.0
					_waited = 0.0
				else:
					state = State.WAIT
					_waited += delta
					if _waited > max_wait and find_node.is_valid():
						_waited = 0.0
						var other: RtsResourceNode = find_node.call(node.kind, position, node)
						if other != null and other != node:
							node = other
							state = State.TO_NODE
		State.GATHERING:
			if node == null or node.is_spent():
				_leave_slot()
				_next_node()
				return
			_gathered += delta
			if _gathered >= gather_time:
				carrying_kind = node.kind
				carrying += node.take(carry - carrying)
				_leave_slot()
				_drop = _nearest_drop()
				state = State.TO_DROP if _drop != Vector3.INF else State.IDLE
		State.TO_DROP:
			if arrived:
				if stockpile != null and carrying > 0:
					stockpile.add(carrying_kind, carrying)
				deposited.emit(carrying_kind, carrying)
				carrying = 0
				if node != null and not node.is_spent():
					state = State.TO_NODE
				else:
					_next_node()


func _next_node() -> void:
	var kind := node.kind if node != null else carrying_kind
	var next: RtsResourceNode = find_node.call(kind, position, null) if find_node.is_valid() else null
	node = next
	state = State.TO_NODE if next != null else State.IDLE


func _nearest_drop() -> Vector3:
	return find_drop.call(position) if find_drop.is_valid() else Vector3.INF


func _leave_slot() -> void:
	if node != null:
		node.release(self)
