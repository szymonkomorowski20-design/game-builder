extends GbScenario
## C4 — playing the whole fight with input only (select + play affordable cards, then end the turn) wins it;
## the win message shows (screenshot).


func run() -> void:
	var view := get_tree().current_scene
	var c: Combat = view.get("combat")
	await wait_frames(2)
	var guard := 0
	while not c.over and guard < 60:
		guard += 1
		var target := -1
		for i in c.deck.hand.size():
			if c.can_play(i):
				target = i
				break
		if target < 0:
			await tap("jump")
			continue
		while int(view.get("selected")) < target:
			await tap("move_right")
		while int(view.get("selected")) > target:
			await tap("move_left")
		await tap("action")
	expect(c.over and c.won, "C4 the fight is won (turn %d, player %d HP)" % [c.turn, c.player_hp])
	expect((node("Message") as Label).visible, "C4 win message shown")
	await shot("win")
