extends GbScenario
## R26 — the chaser reaches a target on the other side of a wall by walking through the gap below it.


func run() -> void:
	await load_scene("res://26-navigation/nav_demo.tscn")
	var c := node("Chaser") as NavChaser
	var target := Vector2(500, 100)
	# Not a fixed frame count: the map is empty for the first ~3 frames and later under load (flaked 1 in ~60 runs).
	expect(await wait_until(func(): return c.map_ready(target), 2.0), "R26 navigation map ready")
	c.go_to(target)
	var arrived := await wait_until(func(): return c.agent.is_navigation_finished(), 8.0)
	expect(arrived, "R26 agent reports navigation finished")
	expect_lt(c.global_position.distance_to(target), 10.0, "R26 chaser is at the target (at %s)" % c.global_position)
	expect_gt(c.max_y, 260.0, "R26 path goes through the gap under the wall")
