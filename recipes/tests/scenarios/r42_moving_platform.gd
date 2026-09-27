extends GbScenario
## R42 — a rider standing on the moving platform travels with it (sideways and upward) and stays on it.


func run() -> void:
	await load_scene("res://42-moving-platform/platform_demo.tscn")
	var platform := node("Platform") as MovingPlatform
	var rider := node("Rider") as PlatformRider
	await wait_until(func() -> bool: return rider.is_on_floor(), 1.0)
	var offset := rider.global_position - platform.global_position
	await wait(1.5)   # 120 px to the right
	var now := rider.global_position - platform.global_position
	expect_near(now.x, offset.x, 2.0, "R42 the rider moved sideways with the platform (offset %s → %s)" % [offset, now])
	expect(rider.is_on_floor(), "R42 the rider is still standing on it")
	await wait(1.0)   # past the corner, going up
	now = rider.global_position - platform.global_position
	expect_near(now.x, offset.x, 2.0, "R42 still on the platform after the corner")
	expect_near(now.y, offset.y, 2.0, "R42 carried upward, not left behind (offset y %.1f)" % now.y)
