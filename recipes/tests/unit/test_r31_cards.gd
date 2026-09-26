extends GutTest
## R31 — seeded shuffle is reproducible, cards are conserved through any sequence of operations,
## reshuffle happens only when the draw pile is empty, hand limit respected.

const CARDS := ["strike", "strike", "strike", "defend", "defend", "bash", "zap", "heal"]


func test_r31_same_seed_same_order() -> void:
	assert_eq(Deck.new(CARDS, 5).draw_pile, Deck.new(CARDS, 5).draw_pile)
	assert_ne(Deck.new(CARDS, 5).draw_pile, Deck.new(CARDS, 6).draw_pile)


func test_r31_global_rng_does_not_affect_the_deck() -> void:
	var a := Deck.new(CARDS, 9).draw_pile
	randf()
	randi()
	assert_eq(Deck.new(CARDS, 9).draw_pile, a)


func test_r31_cards_conserved_over_random_play() -> void:
	var d := Deck.new(CARDS, 1)
	var chooser := RandomNumberGenerator.new()
	chooser.seed = 99
	for turn in 200:
		d.draw(5)
		while d.hand.size() > 2:
			d.play(chooser.randi_range(0, d.hand.size() - 1))
		d.discard_hand()
		assert_eq(d.total(), CARDS.size(), "turn %d" % turn)
	var all := d.draw_pile + d.hand + d.discard
	all.sort()
	var expected := CARDS.duplicate()
	expected.sort()
	assert_eq(all, expected, "exactly the original cards")


func test_r31_reshuffle_only_when_empty() -> void:
	var d := Deck.new(CARDS, 2)
	watch_signals(d)
	d.draw(5)
	d.discard_hand()
	d.draw(3)
	assert_signal_not_emitted(d, "reshuffled")
	d.draw(1)
	assert_signal_emitted(d, "reshuffled")


func test_r31_hand_limit() -> void:
	var d := Deck.new(CARDS, 3)
	d.hand_limit = 4
	assert_eq(d.draw(10).size(), 4)
	assert_null(d.play(9))
