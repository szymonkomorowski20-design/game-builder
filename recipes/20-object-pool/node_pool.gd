class_name NodePool
extends Node
## Reuses instances of one scene (bullets, hit sparks, damage numbers) instead of instantiating/freeing every frame.
## A pooled node should implement `on_acquired()` / `on_released()` if it needs to reset itself.
## Measure first: pooling only pays off for many short-lived nodes (hundreds per second).

@export var scene: PackedScene
@export var max_size := 64   ## hard cap; acquire() returns null beyond it (decide: drop the effect)

var created := 0
var _free: Array[Node] = []


func prewarm(count: int) -> void:
	for i in mini(count, max_size - created):
		var n := _make()
		_park(n)


func acquire() -> Node:
	var n: Node
	if not _free.is_empty():
		n = _free.pop_back()
	elif created < max_size:
		n = _make()
	else:
		return null
	n.process_mode = Node.PROCESS_MODE_INHERIT
	if n is CanvasItem:
		(n as CanvasItem).visible = true
	if n.has_method("on_acquired"):
		n.on_acquired()
	return n


func release(n: Node) -> void:
	if n == null or _free.has(n):
		return   # double release would hand the same node out twice
	if n.has_method("on_released"):
		n.on_released()
	_park(n)


func available() -> int:
	return _free.size()


func _make() -> Node:
	var n := scene.instantiate()
	created += 1
	add_child(n)
	return n


func _park(n: Node) -> void:
	n.process_mode = Node.PROCESS_MODE_DISABLED
	if n is CanvasItem:
		(n as CanvasItem).visible = false
	_free.append(n)
