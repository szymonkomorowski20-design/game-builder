extends GbScenario
## R41 — walking through checkpoint A then dying respawns at A; after B, walking back over A and dying respawns at B.


func run() -> void:
	await load_scene("res://41-checkpoints/checkpoint_demo.tscn")
	var level := get_tree().current_scene
	var mover := node("Mover") as TopDownMover
	var a := node("CheckpointA") as Checkpoint
	var b := node("CheckpointB") as Checkpoint
	hold("move_right")
	await wait_until(func() -> bool: return mover.global_position.x > a.global_position.x + 20.0, 3.0)
	release("move_right")
	level.call("kill")
	await wait_frames(1)
	expect_lt(mover.global_position.distance_to(a.global_position), 1.0, "R41 respawn at checkpoint A")

	hold("move_right")
	await wait_until(func() -> bool: return mover.global_position.x > b.global_position.x + 20.0, 4.0)
	release("move_right")
	hold("move_left")
	await wait_until(func() -> bool: return mover.global_position.x < a.global_position.x - 20.0, 5.0)
	release("move_left")
	level.call("kill")
	await wait_frames(1)
	expect_lt(mover.global_position.distance_to(b.global_position), 1.0, "R41 walking back over A did not move the respawn from B")
	expect_eq(b.flag.modulate, b.active_color, "R41 B shows as active")
	expect_eq(a.flag.modulate, a.idle_color, "R41 A is no longer lit")
