extends GbScenario
## P2 — holding jump reaches jump_height.


func run() -> void:
	var player := node("Player") as Player
	await wait(0.3)
	var floor_y := player.global_position.y
	hold("jump")
	var top := floor_y
	for i in 60:
		await wait_frames(1)
		top = minf(top, player.global_position.y)
	release("jump")
	expect_near(floor_y - top, player.tuning.jump_height, 3.0, "P2 full jump reaches jump_height")
	expect(await wait_until(func() -> bool: return player.is_on_floor(), 2.0), "P2 lands again")
