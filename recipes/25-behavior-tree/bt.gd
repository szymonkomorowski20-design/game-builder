class_name BT
extends RefCounted
## A minimal behavior tree (~80 lines) to show the idea. Each tick walks the tree with a blackboard Dictionary.
##   var tree := BT.Selector.new([
##       BT.Sequence.new([BT.Condition.new(func(bb): return bb.sees_player), BT.Action.new(attack)]),
##       BT.Action.new(patrol),
##   ])
##   tree.tick(blackboard)
## For production trees use LimboAI or Beehave (MIT, editor tooling, debugger).

const SUCCESS := 0
const FAILURE := 1
const RUNNING := 2


class Task extends RefCounted:
	func tick(_bb: Dictionary) -> int:
		return BT.SUCCESS


## Calls fn(bb); a bool result maps to SUCCESS/FAILURE, an int is returned as is (lets actions say RUNNING).
class Action extends Task:
	var fn: Callable

	func _init(f: Callable) -> void:
		fn = f

	func tick(bb: Dictionary) -> int:
		var r = fn.call(bb)
		if typeof(r) == TYPE_BOOL:
			return BT.SUCCESS if r else BT.FAILURE
		return int(r)


class Condition extends Action:
	pass


## Runs children in order until one fails. Remembers a RUNNING child and resumes there next tick.
class Sequence extends Task:
	var children: Array
	var _i := 0

	func _init(c: Array) -> void:
		children = c

	func tick(bb: Dictionary) -> int:
		while _i < children.size():
			var s: int = children[_i].tick(bb)
			if s == BT.RUNNING:
				return BT.RUNNING
			if s == BT.FAILURE:
				_i = 0
				return BT.FAILURE
			_i += 1
		_i = 0
		return BT.SUCCESS


## Tries children in priority order every tick (reactive): the first non-FAILURE wins.
class Selector extends Task:
	var children: Array

	func _init(c: Array) -> void:
		children = c

	func tick(bb: Dictionary) -> int:
		for child in children:
			var s: int = child.tick(bb)
			if s != BT.FAILURE:
				return s
		return BT.FAILURE


class Inverter extends Task:
	var child: Task

	func _init(c: Task) -> void:
		child = c

	func tick(bb: Dictionary) -> int:
		var s := child.tick(bb)
		if s == BT.RUNNING:
			return s
		return BT.FAILURE if s == BT.SUCCESS else BT.SUCCESS
