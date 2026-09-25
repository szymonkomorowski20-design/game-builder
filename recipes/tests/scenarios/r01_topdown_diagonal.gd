extends GbScenario
## R01 — diagonal movement is not faster than straight movement; friction stops the mover.


func run() -> void:
	await load_scene("res://01-topdown-movement/topdown.tscn")
	var m := node("Mover") as TopDownMover
	hold("move_right")
	hold("move_down")
	await wait(0.5)
	expect_near(m.velocity.length(), m.speed, 0.5, "R01 diagonal speed equals speed, not speed·√2")
	release("move_right")
	release("move_down")
	await wait(0.5)
	expect_near(m.velocity.length(), 0.0, 0.01, "R01 friction stops the mover")
