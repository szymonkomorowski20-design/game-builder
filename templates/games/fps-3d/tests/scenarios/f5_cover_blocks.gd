extends GbScenario
## F5 — a wall stops shots: aiming at the target behind the cover from the spawn hits the cover, not the target.


func run() -> void:
	var player := node("Player") as FpsPlayer
	var hidden := node("TargetBehindCover") as ShootTarget
	var cover := node("Cover")
	await wait(0.2)
	player.aim_at(hidden.global_position)
	await wait_frames(2)
	var health := hidden.health
	await tap("shoot")
	expect_eq(hidden.health, health, "F5 the target behind the cover took no damage")
	expect(player.weapon.last_hit == cover, "F5 the shot hit the cover (hit: %s)" % player.weapon.last_hit)
