class_name Deck
extends RefCounted
## Draw pile / hand / discard with a seeded shuffle (Fisher–Yates on the deck's own RNG — replays and seeded runs
## stay identical). Cards are never created or lost: total() is constant. (Recipe 31.)

signal reshuffled

var draw_pile: Array = []
var hand: Array = []
var discard: Array = []
var hand_limit := 10
var rng := RandomNumberGenerator.new()


func _init(cards: Array = [], seed_value: int = 1) -> void:
	rng.seed = seed_value
	draw_pile = cards.duplicate()
	shuffle(draw_pile)


func shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func draw(n: int) -> Array:
	var drawn: Array = []
	for i in n:
		if hand.size() >= hand_limit:
			break
		if draw_pile.is_empty():
			if discard.is_empty():
				break
			draw_pile = discard
			discard = []
			shuffle(draw_pile)
			reshuffled.emit()
		var c = draw_pile.pop_back()
		hand.append(c)
		drawn.append(c)
	return drawn


func play(index: int) -> Variant:
	if index < 0 or index >= hand.size():
		return null
	var c = hand.pop_at(index)
	discard.append(c)
	return c


func discard_hand() -> void:
	discard.append_array(hand)
	hand.clear()


func total() -> int:
	return draw_pile.size() + hand.size() + discard.size()
