extends GbScenario
## P5 — releasing jump early gives a lower jump.


func run() -> void:
	var player := node("Player") as Player
	await wait(0.3)
	var floor_y := player.global_position.y
	await tap("jump")
	var top := floor_y
	for i in 60:
		await wait_frames(1)
		top = minf(top, player.global_position.y)
	var height := floor_y - top
	expect_gt(height, 1.0, "P5 a tap still jumps")
	expect_lt(height, player.tuning.jump_height * 0.6, "P5 a tap jumps clearly lower than a held jump")
