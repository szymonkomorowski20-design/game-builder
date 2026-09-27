extends GbScenario
## F6 — shooting every target (walking round the cover, re-aiming at the moving one before each shot) wins the arena.

const SPOTS := {
	"TargetBehindCover": Vector3(6.0, 0.05, -11.0),   # beside the cover — a clear line
}


func run() -> void:
	var level := get_tree().current_scene
	var player := node("Player") as FpsPlayer
	await wait(0.2)
	await shot("arena_start")
	for name in ["TargetLeft", "TargetRight", "TargetMoving", "TargetFar", "TargetBehindCover"]:
		var target := node(name) as ShootTarget
		if SPOTS.has(name):
			player.global_position = SPOTS[name]
		var guard := 0
		while is_instance_valid(target) and guard < 20:
			player.aim_at(target.global_position)
			await tap("shoot")
			await wait(player.tuning.fire_interval + 0.02)
			guard += 1
		expect(not is_instance_valid(target), "F6 %s destroyed" % name)
	expect(bool(level.get("completed")), "F6 all targets down → arena completed")
	expect((node("HUD/Message") as Label).visible, "F6 end message visible")
	await shot("arena_win")
