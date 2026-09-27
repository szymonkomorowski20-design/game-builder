extends GbScenario
## D6 — falling into the gap below kill_y respawns at Spawn and counts a death.


func run() -> void:
	var level := get_tree().current_scene
	var player := node("Player") as Player
	var spawn := node("Spawn") as Marker3D
	await wait(0.2)
	player.teleport(Vector3(-4.0, 0.05, -11.25))   # above the gap, away from the gap coin
	var respawned := await wait_until(func() -> bool: return int(level.get("deaths")) == 1, 3.0)
	expect(respawned, "D6 falling counts a death")
	expect_lt(player.global_position.distance_to(spawn.global_position), 0.5, "D6 back at Spawn")
