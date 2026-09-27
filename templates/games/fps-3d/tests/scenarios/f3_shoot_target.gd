extends GbScenario
## F3 — aiming at a target and pressing shoot hits it; each hit removes `damage` health; at 0 it is gone and the HUD
## counts it. A shot shows the crosshair on the target (screenshot).


func _shoot_once(player: FpsPlayer) -> void:
	await tap("shoot")
	await wait(player.tuning.fire_interval + 0.02)


func run() -> void:
	var level := get_tree().current_scene
	var player := node("Player") as FpsPlayer
	var target := node("TargetLeft") as ShootTarget
	await wait(0.2)
	player.aim_at(target.global_position)
	await wait_frames(2)
	await shot("aim_on_target")
	var start_health := target.health
	await _shoot_once(player)
	expect_eq(target.health, start_health - player.tuning.damage, "F3 one hit removes damage")
	expect(player.weapon.last_hit == target, "F3 the shot hit the aimed target")
	while is_instance_valid(target) and target.health > 0:
		await _shoot_once(player)
	await wait_frames(2)
	expect(not is_instance_valid(target), "F3 the target is destroyed at 0 health")
	expect_eq(int(level.get("targets_left")), int(level.get("targets_total")) - 1, "F3 one target down")
	expect_eq((node("HUD/Targets") as Label).text, "Cele: 1/%d" % int(level.get("targets_total")), "F3 HUD counts it")
