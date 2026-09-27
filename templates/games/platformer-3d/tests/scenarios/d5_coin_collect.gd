extends GbScenario
## D5 — running into the coin ahead of the spawn collects it once and updates the HUD.


func run() -> void:
	var level := get_tree().current_scene
	await wait(0.3)
	hold("move_up")
	var got := await wait_until(func() -> bool: return int(level.get("coins_collected")) == 1, 2.0)
	release("move_up")
	expect(got, "D5 the coin ahead is collected")
	await wait(0.3)
	expect_eq(int(level.get("coins_collected")), 1, "D5 collected once, not again")
	expect_eq((node("HUD/Coins") as Label).text, "Monety: 1/5", "D5 HUD shows 1/5")
