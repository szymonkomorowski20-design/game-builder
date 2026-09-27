extends GbScenario
## R51 — the bot fights the boss with the real key: hits land until the 66% threshold, the hit that crosses it stops
## there and the boss turns invulnerable (further hits blocked), after the transition hits land again; over the whole
## fight every strike was telegraphed for at least 0.4 s on screen; the boss dies.


func run() -> void:
	await load_scene("res://51-boss-phases/boss_demo.tscn")
	var demo := node(".") as BossDemo
	await wait_frames(3)
	for i in 3:
		await tap("action")
	expect_eq(demo.brain.health, 198, "R51 300 → 260 → 220 → stops at the 66% threshold (198)")
	expect_eq(demo.brain.phase, 1, "R51 phase 1")
	await tap("action")
	expect_eq(demo.hits_blocked, 1, "R51 a hit during the transition is blocked")
	expect_eq(demo.brain.health, 198, "R51 still at the threshold")
	await shot("boss_transition")
	await wait(1.1)
	await tap("action")
	expect_eq(demo.brain.health, 158, "R51 hits land again after the transition")
	await wait(3.0)
	var ok := await wait_until(func() -> bool: return demo.brain.is_telegraphing(), 3.0)
	expect(ok, "R51 the boss telegraphs its next move")
	await wait(0.3)
	await shot("boss_telegraph")
	while demo.brain.health > 0:
		await tap("action")
		if demo.brain.state == BossBrain.State.TRANSITION:
			await wait(1.1)
	expect_eq(demo.brain.state, BossBrain.State.DEAD, "R51 the boss dies")
	expect_gt(demo.telegraph_seconds.size(), 1, "R51 at least two strikes were measured")
	var shortest := 99.0
	for s in demo.telegraph_seconds:
		shortest = minf(shortest, s)
	expect_gt(shortest, 0.4 - 0.02, "R51 every strike was telegraphed on screen for ≥ 0.4 s (shortest %.2f)" % shortest)
