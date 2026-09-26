extends GbScenario
## C3 — with no energy left, trying to play shows "Za mało energii" and changes nothing.


func run() -> void:
	var view := get_tree().current_scene
	var c: Combat = view.get("combat")
	await wait_frames(2)
	# Spend energy by playing card 0 while it is affordable.
	while c.can_play(0):
		await tap("action")
	expect(c.energy < 2, "C3 energy spent (left: %d)" % c.energy)
	var unaffordable := -1
	for i in c.deck.hand.size():
		if not c.can_play(i):
			unaffordable = i
			break
	if unaffordable < 0:
		expect(c.deck.hand.is_empty(), "C3 every remaining card was affordable only if the hand is empty")
		return
	while int(view.get("selected")) < unaffordable:
		await tap("move_right")
	var before := [c.energy, c.enemy_hp, c.deck.hand.size()]
	await tap("action")
	expect_eq([c.energy, c.enemy_hp, c.deck.hand.size()], before, "C3 nothing changed")
	expect((node("Message") as Label).visible and (node("Message") as Label).text == "Za mało energii", "C3 message shown")
