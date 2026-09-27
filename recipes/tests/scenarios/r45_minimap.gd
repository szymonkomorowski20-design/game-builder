extends GbScenario
## R45 — the player's dot follows the player at the map scale; every tracked thing has a dot; one far outside the
## level sits on the map's edge; a screenshot shows the map in the corner.


func run() -> void:
	await load_scene("res://45-minimap/minimap_demo.tscn")
	var mm := node("HUD/Minimap") as Minimap
	var mover := node("Mover") as TopDownMover
	await wait_frames(3)
	expect_eq(mm.points.size(), 4, "R45 a dot for the player, the enemy, the coin and the far enemy")
	var before: Vector2 = mm.points[&"Mover"]
	var x0 := mover.global_position.x
	await press("move_right", 0.5)
	await wait_frames(3)
	var scale := minf(mm.size.x / mm.world_rect.size.x, mm.size.y / mm.world_rect.size.y)
	var after: Vector2 = mm.points[&"Mover"]
	expect_near(after.x - before.x, (mover.global_position.x - x0) * scale, 0.05, "R45 the dot moved by distance × map scale")
	expect_near(after.y, before.y, 0.05, "R45 no vertical change")
	expect_near((mm.points[&"FarAway"] as Vector2).x, mm.world_to_map(Vector2(mm.world_rect.end.x, 0)).x, 0.001, "R45 the far enemy is pinned to the right edge")
	await shot("minimap")
