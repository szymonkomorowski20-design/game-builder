extends GutTest
## R48 — stat modifiers and boons. StatSheet: (base + flat) × (1 + Σ increased) × Π more, independent of order;
## removing a source removes all its modifiers. BoonPool: offers up to N distinct boons the player doesn't own,
## deterministic for a seed; rarity follows the weights (luck shifts them); a synergy boon is offered only once the
## player owns boons of every tag it requires; a small pool returns what it has.


func _mod(stat: StringName, op: StatModifier.Op, value: float, source: StringName = &"") -> StatModifier:
	var m := StatModifier.new()
	m.stat = stat
	m.op = op
	m.value = value
	m.source = source
	return m


func _boon(id: StringName, tags: Array[StringName], requires: Array[StringName] = [], stat: StringName = &"damage", value: float = 0.2) -> Boon:
	var b := Boon.new()
	b.id = id
	b.tags = tags
	b.requires_tags = requires
	b.modifiers = [_mod(stat, StatModifier.Op.INCREASED, value)]
	return b


func test_r48_stat_formula_and_order_independence() -> void:
	var a := StatSheet.new({&"damage": 10.0})
	a.add(_mod(&"damage", StatModifier.Op.FLAT, 5))
	a.add(_mod(&"damage", StatModifier.Op.INCREASED, 0.2))
	a.add(_mod(&"damage", StatModifier.Op.INCREASED, 0.3))
	a.add(_mod(&"damage", StatModifier.Op.MORE, 1.5))
	assert_almost_eq(a.value(&"damage"), 33.75, 1e-6, "(10 + 5) × (1 + 0.5) × 1.5")
	var b := StatSheet.new({&"damage": 10.0})
	b.add(_mod(&"damage", StatModifier.Op.MORE, 1.5))
	b.add(_mod(&"damage", StatModifier.Op.INCREASED, 0.3))
	b.add(_mod(&"damage", StatModifier.Op.FLAT, 5))
	b.add(_mod(&"damage", StatModifier.Op.INCREASED, 0.2))
	assert_almost_eq(b.value(&"damage"), a.value(&"damage"), 1e-6, "same result in any order")
	assert_eq(a.value(&"speed"), 0.0, "unknown stat → 0")


func test_r48_remove_source() -> void:
	var s := StatSheet.new({&"speed": 5.0})
	s.add(_mod(&"speed", StatModifier.Op.INCREASED, 0.4, &"swift"))
	s.add(_mod(&"speed", StatModifier.Op.FLAT, 1.0, &"swift"))
	s.add(_mod(&"speed", StatModifier.Op.INCREASED, 0.1, &"boots"))
	assert_almost_eq(s.value(&"speed"), 6.0 * 1.5, 1e-6)
	s.remove_source(&"swift")
	assert_almost_eq(s.value(&"speed"), 5.0 * 1.1, 1e-6, "only the boots remain")


func test_r48_changed_signal() -> void:
	var s := StatSheet.new({&"speed": 5.0})
	var got := []
	s.changed.connect(func(stat: StringName): got.append(stat))
	s.add(_mod(&"speed", StatModifier.Op.FLAT, 1.0, &"x"))
	s.remove_source(&"x")
	assert_eq(got, [&"speed", &"speed"])


func _pool() -> BoonPool:
	var p := BoonPool.new()
	p.boons = [_boon(&"fire_strike", [&"fire"]), _boon(&"fire_dash", [&"fire"]), _boon(&"swift_feet", [&"speed"]),
		_boon(&"quick_hands", [&"speed"]), _boon(&"iron_skin", [&"guard"]),
		_boon(&"blazing_rush", [&"fire", &"speed"], [&"fire", &"speed"])]
	return p


func test_r48_offer_is_distinct_unowned_and_deterministic() -> void:
	var p := _pool()
	var owned: Array[StringName] = [&"fire_strike"]
	var first := p.offer(1234, owned, 3)
	assert_eq(first.size(), 3)
	var ids := first.map(func(o: BoonOffer): return o.boon.id)
	var unique := {}
	for id in ids:
		unique[id] = true
	assert_eq(unique.size(), ids.size(), "no duplicates")
	for seed in 100:
		var any_seed := p.offer(seed, owned, 3).map(func(o: BoonOffer): return o.boon.id)
		assert_false(any_seed.has(&"fire_strike"), "never offers what the player owns (seed %d)" % seed)
	var again := p.offer(1234, owned, 3).map(func(o: BoonOffer): return o.boon.id)
	assert_eq(again, ids, "same seed → same offer")


func test_r48_synergy_needs_all_required_tags() -> void:
	var p := _pool()
	for seed in 200:
		var ids := p.offer(seed, [&"fire_strike"] as Array[StringName], 3).map(func(o: BoonOffer): return o.boon.id)
		assert_false(ids.has(&"blazing_rush"), "fire only → no fire+speed synergy (seed %d)" % seed)
	var seen := false
	for seed in 200:
		var ids := p.offer(seed, [&"fire_strike", &"swift_feet"] as Array[StringName], 3).map(func(o: BoonOffer): return o.boon.id)
		seen = seen or ids.has(&"blazing_rush")
	assert_true(seen, "fire + speed owned → the synergy shows up")


func test_r48_small_pool_returns_what_it_has() -> void:
	var p := _pool()
	var owned: Array[StringName] = [&"fire_strike", &"fire_dash", &"swift_feet", &"quick_hands"]
	var offer := p.offer(7, owned, 3)
	# StringName sorts by address, not alphabetically — compare as Strings.
	var ids := offer.map(func(o: BoonOffer) -> String: return String(o.boon.id))
	ids.sort()
	assert_eq(ids, ["blazing_rush", "iron_skin"], "only two left (the synergy is now allowed)")


func test_r48_rarity_follows_weights_and_luck() -> void:
	var p := _pool()
	p.rarity_weights = {Boon.Rarity.COMMON: 70.0, Boon.Rarity.RARE: 25.0, Boon.Rarity.EPIC: 5.0}
	var counts := {Boon.Rarity.COMMON: 0, Boon.Rarity.RARE: 0, Boon.Rarity.EPIC: 0}
	for seed in 4000:
		counts[p.offer(seed, [] as Array[StringName], 1)[0].rarity] += 1
	assert_almost_eq(counts[Boon.Rarity.COMMON] / 4000.0, 0.70, 0.03)
	assert_almost_eq(counts[Boon.Rarity.EPIC] / 4000.0, 0.05, 0.02)
	# Every card of a 3-card offer follows the weights too, and cards of one offer are not all the same rarity
	# more often than chance allows (0.7³ + 0.25³ + 0.05³ ≈ 36%).
	var common_cards := 0
	var uniform_offers := 0
	for seed in 2000:
		var o := p.offer(seed, [] as Array[StringName], 3)
		for card in o:
			common_cards += 1 if card.rarity == Boon.Rarity.COMMON else 0
		uniform_offers += 1 if o[0].rarity == o[1].rarity and o[1].rarity == o[2].rarity else 0
	assert_almost_eq(common_cards / 6000.0, 0.70, 0.03, "all three cards follow the weights")
	assert_almost_eq(uniform_offers / 2000.0, 0.36, 0.05, "no correlation between cards")
	p.luck = 1.0
	var epic := 0
	for seed in 4000:
		epic += 1 if p.offer(seed, [] as Array[StringName], 1)[0].rarity == Boon.Rarity.EPIC else 0
	assert_gt(epic / 4000.0, 0.08, "luck makes epics more likely")


func test_r48_rarity_scales_modifier_values() -> void:
	var b := _boon(&"fire_strike", [&"fire"], [], &"damage", 0.2)
	var s := StatSheet.new({&"damage": 10.0})
	b.apply(s, Boon.Rarity.RARE)
	assert_almost_eq(s.value(&"damage"), 10.0 * (1.0 + 0.2 * Boon.RARITY_SCALE[Boon.Rarity.RARE]), 1e-6)
	b.remove(s)
	assert_almost_eq(s.value(&"damage"), 10.0, 1e-6, "removing the boon restores the stat")
