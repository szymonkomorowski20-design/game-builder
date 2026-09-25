extends GbScenario


func run() -> void:
	var player := node("Player") as CharacterBody2D
	await wait(0.3)
	var start_x := player.position.x
	await press("move_right", 1.0)
	expect_near(player.position.x, start_x + 120.0, 2.0, "walks 120 px in 1 s at SPEED 120")
	var floor_y := player.position.y
	await tap("jump")
	await wait(0.2)
	expect_lt(player.position.y, floor_y - 20.0, "is in the air after jump")
	expect(await wait_until(func(): return player.is_on_floor(), 3.0), "lands again")
