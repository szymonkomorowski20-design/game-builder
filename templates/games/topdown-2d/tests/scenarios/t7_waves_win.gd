extends GbScenario
## T7 — clearing a wave starts the next after wave_delay; clearing the last wave wins.


func _kill_all() -> void:
	for e in nodes_in_group("enemies"):
		e.take_damage(99)


func run() -> void:
	var arena := get_tree().current_scene
	_kill_all()
	await wait_frames(2)
	expect_eq(int(arena.get("wave")), 0, "T7 still wave 1 during the delay")
	var next := await wait_until(func() -> bool: return int(arena.get("wave")) == 1, 1.5)
	expect(next, "T7 wave 2 started")
	await wait_frames(2)
	expect_eq(nodes_in_group("enemies").size(), 3, "T7 wave 2 has 3 enemies")
	_kill_all()
	await wait_frames(2)
	expect(bool(arena.get("won")), "T7 clearing the last wave wins")
	expect((node("HUD/Message") as Label).visible, "T7 win message shown")
	await shot("win")
