extends GbScenario
## R44 — the AnimationTree follows the body: idle at rest, run while moving, jump while rising, fall on the way down,
## idle again after landing (checked on the state machine's current node, not on the animator's own variable).


func _current(tree: AnimationTree) -> StringName:
	return (tree.get("parameters/playback") as AnimationNodeStateMachinePlayback).get_current_node()


func run() -> void:
	await load_scene("res://44-animation-tree/anim_demo.tscn")
	var tree := node("Body/AnimationTree") as AnimationTree
	var body := node("Body") as AnimBody
	await wait(0.3)
	expect_eq(_current(tree), AnimStates.IDLE, "R44 idle at rest")
	hold("move_right")
	await wait(0.3)
	expect_eq(_current(tree), AnimStates.RUN, "R44 run while moving")
	release("move_right")
	await wait(0.2)
	await tap("jump")
	await wait_frames(3)
	expect_eq(_current(tree), AnimStates.JUMP, "R44 jump while rising")
	var falling := await wait_until(func() -> bool: return body.velocity.y > 50.0, 2.0)
	await wait_frames(3)
	expect(falling and _current(tree) == AnimStates.FALL, "R44 fall on the way down (%s)" % _current(tree))
	await wait_until(func() -> bool: return body.is_on_floor(), 2.0)
	await wait(0.2)
	expect_eq(_current(tree), AnimStates.IDLE, "R44 idle again after landing")
