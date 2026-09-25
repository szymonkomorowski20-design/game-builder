extends GbScenario
## P6 — touching a coin collects it once and updates the HUD.


func run() -> void:
	var level := get_tree().current_scene
	var player := node("Player") as Player
	var total: int = level.get("coins_total")
	expect_eq(total, 5, "P6 the level has 5 coins")
	player.teleport(Vector2(860.0, 301.0))
	await press("move_right", 0.6)
	expect_eq(int(level.get("coins_collected")), 1, "P6 one coin collected")
	await wait(0.2)
	expect_eq(int(level.get("coins_collected")), 1, "P6 a coin is collected only once")
	expect(String((node("HUD/Coins") as Label).text).contains("1/5"), "P6 HUD shows 1/5")
