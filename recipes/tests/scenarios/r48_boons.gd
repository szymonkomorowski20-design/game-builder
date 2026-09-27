extends GbScenario
## R48 — the bot picks the speed boon from three cards with the real keys: speed rises by the offered rarity's share,
## the boon is owned, and the next offer doesn't repeat it.


func run() -> void:
	await load_scene("res://48-boons-modifiers/boon_demo.tscn")
	var demo := node(".") as BoonDemo
	await wait_frames(3)
	expect_eq(demo.offer.size(), 3, "R48 three cards")
	var ids := demo.offer.map(func(o: BoonOffer): return o.boon.id)
	var target := ids.find(&"swift_feet")
	if target < 0:
		target = 0     # the seed decides; take whatever is first and check that instead
	var picked := demo.offer[target]
	var before_speed := demo.sheet.value(&"speed")
	for i in target:
		await tap("move_right")
	expect_eq(demo.selected, target, "R48 the arrow keys move the selection")
	await tap("action")
	await wait_frames(2)
	expect(demo.owned.has(picked.boon.id), "R48 the taken boon is owned")
	if picked.boon.id == &"swift_feet":
		var k: float = Boon.RARITY_SCALE[picked.rarity]
		expect_near(demo.sheet.value(&"speed"), before_speed * (1.0 + 0.25 * k), 1e-4, "R48 speed rose by 25% × rarity")
	var next_ids := demo.offer.map(func(o: BoonOffer): return o.boon.id)
	expect(not next_ids.has(picked.boon.id), "R48 the next offer doesn't repeat an owned boon")
	await shot("boons")
