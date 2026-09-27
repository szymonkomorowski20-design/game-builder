extends GbScenario
## R47 — the bot presses attack at a dummy: one press → one hit of the first swing; three presses in rhythm → the
## three swings in order, each hitting exactly once however many frames the hitbox overlaps; waiting resets it.


func run() -> void:
	await load_scene("res://47-melee-combo/combo_demo.tscn")
	var dummy := node("Dummy") as ComboDummy
	await wait_frames(5)
	await tap("action")
	await wait(0.6)
	expect_eq(dummy.hits, [10], "R47 one press → one hit of the first swing")
	await tap("action")
	await wait(0.2)
	await tap("action")
	await wait(0.2)
	await tap("action")
	await wait(0.9)
	expect_eq(dummy.hits, [10, 10, 12, 25], "R47 three presses in rhythm → the three swings, one hit each")
	expect_gt(dummy.pushed.length(), 0.0, "R47 hits push the target away from the attacker")
	await tap("action")
	await wait(0.6)
	expect_eq(dummy.hits.back(), 10, "R47 after a pause the combo starts from the first swing again")
	await shot("melee_combo")
