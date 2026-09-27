class_name AnimStates
extends RefCounted
## Which animation state a platformer body is in — pure, so the rules are unit-tested instead of eyeballed — and a
## helper that builds an AnimationTree state machine in code (every state reachable from every other, short
## cross-fade) for when you'd rather not wire the graph by hand in the editor.

const IDLE := &"idle"
const RUN := &"run"
const JUMP := &"jump"
const FALL := &"fall"


static func state_for(on_floor: bool, velocity: Vector2, run_threshold: float = 10.0) -> StringName:
	if not on_floor:
		return JUMP if velocity.y < 0.0 else FALL
	return RUN if absf(velocity.x) > run_threshold else IDLE


## A state machine with one AnimationNodeAnimation per name (playing the animation of the same name) and a
## transition between every pair, cross-fading over `xfade` seconds. Assign it to AnimationTree.tree_root.
static func build_machine(names: Array[StringName], xfade: float = 0.08) -> AnimationNodeStateMachine:
	var sm := AnimationNodeStateMachine.new()
	for i in names.size():
		var node := AnimationNodeAnimation.new()
		node.animation = names[i]
		sm.add_node(names[i], node, Vector2(i * 160, 0))
	for from in names:
		for to in names:
			if from != to:
				var t := AnimationNodeStateMachineTransition.new()
				t.xfade_time = xfade
				sm.add_transition(from, to, t)
	var start := AnimationNodeStateMachineTransition.new()
	sm.add_transition(&"Start", names[0], start)
	return sm
