extends GutTest
## Combat rules: energy, cost, damage, block, enemy intents, conservation of cards, win/lose, determinism.

const CARDS := preload("res://data/cards.tres")
const TUNING := preload("res://data/combat_tuning.tres")


func _combat(t: CombatTuning = TUNING) -> Combat:
	return Combat.new(CARDS, t)


func _index_of(c: Combat, id: String) -> int:
	return c.deck.hand.find(id)


func test_first_turn_state() -> void:
	var c := _combat()
	assert_eq(c.deck.hand.size(), TUNING.hand_size)
	assert_eq(c.energy, TUNING.energy_per_turn)
	assert_eq(c.player_hp, TUNING.player_hp)
	assert_eq(c.enemy_hp, TUNING.enemy_hp)
	assert_eq(c.turn, 1)


func test_playing_a_card_spends_energy_and_applies_its_effect() -> void:
	var c := _combat()
	var id: String = c.deck.hand[0]
	assert_true(c.play(0))
	assert_eq(c.energy, TUNING.energy_per_turn - CARDS.cost(id))
	assert_eq(c.enemy_hp, TUNING.enemy_hp - CARDS.damage(id))
	assert_eq(c.block, CARDS.block(id))
	assert_eq(c.deck.hand.size(), TUNING.hand_size - 1)


func test_not_enough_energy_changes_nothing() -> void:
	var c := _combat()
	while c.energy > 0 and c.deck.hand.size() > 0:
		var i := 0
		while i < c.deck.hand.size() and not c.can_play(i):
			i += 1
		if i == c.deck.hand.size():
			break
		c.play(i)
	var before := [c.energy, c.enemy_hp, c.block, c.deck.hand.size()]
	for i in c.deck.hand.size():
		if CARDS.cost(c.deck.hand[i]) > c.energy:
			assert_false(c.play(i))
	assert_eq([c.energy, c.enemy_hp, c.block, c.deck.hand.size()], before)


func test_block_absorbs_the_enemy_attack_then_resets() -> void:
	var c := _combat()
	# Not dependent on the shuffled hand: a changed seed must not silently skip this check.
	var blocked := CARDS.block("defend")
	c.block = blocked
	var intent := c.intent()
	assert_lt(blocked, intent, "the default first intent is larger than one defend")
	c.end_turn()
	assert_eq(c.player_hp, TUNING.player_hp - maxi(0, intent - blocked))
	assert_eq(c.block, 0, "block resets at the start of the turn")
	assert_eq(c.energy, TUNING.energy_per_turn)
	assert_eq(c.deck.hand.size(), TUNING.hand_size)


func test_intents_cycle() -> void:
	var c := _combat()
	var seen: Array = []
	for i in 4:
		seen.append(c.intent())
		c.end_turn()
	assert_eq(seen, [6, 8, 12, 6])


func test_cards_are_conserved() -> void:
	var c := _combat()
	var total := CARDS.starting_deck.size()
	for turn in 12:
		if c.over:
			break
		if c.can_play(0):
			c.play(0)
		assert_eq(c.deck.total(), total, "turn %d" % turn)
		c.end_turn()


func test_greedy_play_wins_the_default_fight() -> void:
	# Balance contract: playing every affordable card each turn beats the default enemy within 5 turns.
	var c := _combat()
	while not c.over and c.turn <= 10:
		var played := true
		while played:
			played = false
			for i in c.deck.hand.size():
				if c.can_play(i):
					c.play(i)
					played = true
					break
		c.end_turn()
	assert_true(c.won, "greedy play wins")
	assert_lte(c.turn, 5, "within 5 turns")


func test_losing_ends_the_fight() -> void:
	var t: CombatTuning = TUNING.duplicate()
	t.enemy_hp = 999
	t.enemy_intents = PackedInt32Array([25])
	var c := _combat(t)
	watch_signals(c)
	c.end_turn()
	c.end_turn()
	assert_true(c.over)
	assert_false(c.won)
	assert_eq(c.player_hp, 0)
	assert_signal_emitted_with_parameters(c, "ended", [false])
	assert_false(c.play(0), "no plays after the end")


func test_same_seed_same_first_hand() -> void:
	assert_eq(_combat().deck.hand, _combat().deck.hand)
