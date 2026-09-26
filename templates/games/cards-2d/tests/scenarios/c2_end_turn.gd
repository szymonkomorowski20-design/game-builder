extends GbScenario
## C2 — jump ends the turn: the enemy hits for its intent minus block, a new hand of 5 and full energy arrive,
## the next intent is shown.


func run() -> void:
	var view := get_tree().current_scene
	var c: Combat = view.get("combat")
	var t: CombatTuning = view.get("tuning")
	await wait_frames(2)
	var intent := c.intent()
	var hp := c.player_hp
	var block := c.block
	await tap("jump")
	expect_eq(c.player_hp, hp - maxi(0, intent - block), "C2 enemy attack applied")
	expect_eq(c.turn, 2, "C2 turn 2")
	expect_eq(c.energy, t.energy_per_turn, "C2 energy refilled")
	expect_eq(c.deck.hand.size(), t.hand_size, "C2 new hand")
	expect((node("EnemyInfo") as Label).text.ends_with(str(c.intent())), "C2 next intent shown: %s" % (node("EnemyInfo") as Label).text)
