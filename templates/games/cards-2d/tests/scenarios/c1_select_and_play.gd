extends GbScenario
## C1 — move_right selects the next card, action plays it: energy and enemy HP change by the card's data.


func run() -> void:
	var view := get_tree().current_scene
	var c: Combat = view.get("combat")
	var cards: CardSet = view.get("card_set")
	await wait_frames(2)
	await tap("move_right")
	expect_eq(int(view.get("selected")), 1, "C1 move_right selects card 2")
	var id: String = c.deck.hand[1]
	var energy := c.energy
	var enemy := c.enemy_hp
	await tap("action")
	expect_eq(c.energy, energy - cards.cost(id), "C1 energy spent by the card's cost")
	expect_eq(c.enemy_hp, enemy - cards.damage(id), "C1 enemy HP reduced by the card's damage")
	expect_eq(c.deck.hand.size(), 4, "C1 card left the hand")
	expect_eq((node("Hand") as HBoxContainer).get_child_count(), 4, "C1 hand view shows 4 cards")
