extends GbScenario
## P7 — falling below kill_y respawns at Spawn and counts a death.


func run() -> void:
	var level := get_tree().current_scene
	var player := node("Player") as Player
	var spawn := (node("Spawn") as Marker2D).global_position
	player.teleport(Vector2(448.0, 250.0))
	var respawned := await wait_until(func() -> bool: return int(level.get("deaths")) == 1, 3.0)
	expect(respawned, "P7 death counted after falling into the gap")
	expect_near(player.global_position.distance_to(spawn), 0.0, 30.0, "P7 player back at Spawn")
