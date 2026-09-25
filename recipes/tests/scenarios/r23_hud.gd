extends GbScenario
## R23 — the HUD mirrors Health and Wallet through signals only; gameplay code never touches the HUD.


func run() -> void:
	await load_scene("res://23-hud/hud_demo.tscn")
	var hp := node("Player/Health") as Health
	var bar := node("Hud/HpBar") as ProgressBar
	var coins := node("Hud/CoinsLabel") as Label
	expect_eq(int(bar.max_value), 5, "R23 bar max = max health")
	expect_eq(int(bar.value), 5, "R23 bar starts full")

	hp.take_damage(2)
	await wait_frames(1)
	expect_eq(int(bar.value), 3, "R23 damage updates the bar")
	hp.heal(1)
	await wait_frames(1)
	expect_eq(int(bar.value), 4, "R23 healing updates the bar")

	var wallet := Wallet.new(3)
	node("Hud").bind_wallet(wallet)
	expect(coins.text.ends_with("3"), "R23 coins shown on bind: '%s'" % coins.text)
	wallet.earn(10)
	expect(coins.text.ends_with("13"), "R23 coins update on earn: '%s'" % coins.text)
