extends GutTest
## R59 — RTS economy. Stockpile: all-or-nothing spending, refunds, supply reserved at the start and capped by
## max_supply. Resource node: slots (saturation), take, depletion. Gatherer: the full loop with real walking (a simple
## host below), waiting for a slot, the nearest drop-off, moving on from a spent node, stop() keeps the load; the
## income formula matches the simulated income and saturates.


class Host:
	## Walks a gatherer's body toward its target at `speed` and ticks it — what a game's worker node does.
	var g: RtsGatherer
	var speed := 4.0

	func _init(gatherer: RtsGatherer, at: Vector3) -> void:
		g = gatherer
		g.position = at

	func step(dt: float) -> void:
		var t := g.target()
		var arrived := t == Vector3.INF
		if t != Vector3.INF:
			var d := g.position.distance_to(t)
			if d <= speed * dt:
				g.position = t
				arrived = true
			else:
				g.position += (t - g.position) / d * speed * dt
		g.tick(dt, arrived)


func _gatherer(stock: RtsStockpile, node: RtsResourceNode, drop: Vector3) -> RtsGatherer:
	var g := RtsGatherer.new()
	g.stockpile = stock
	g.gather_time = 1.0
	g.carry = 10
	g.find_drop = func(_from: Vector3) -> Vector3: return drop
	g.gather(node)
	return g


func _run(hosts: Array, seconds: float) -> void:
	var dt := 1.0 / 30.0
	for i in int(seconds / dt):
		for h in hosts:
			(h as Host).step(dt)


func test_r59_spending_is_all_or_nothing() -> void:
	var s := RtsStockpile.new({&"gold": 100, &"wood": 30})
	assert_false(s.spend({&"gold": 80, &"wood": 40}), "not enough wood")
	assert_eq(s.amount(&"gold"), 100, "and the gold was not taken")
	assert_true(s.spend({&"gold": 80, &"wood": 20}))
	assert_eq(s.amount(&"gold"), 20)
	s.refund({&"gold": 80, &"wood": 20}, 0.75)
	assert_eq(s.amount(&"gold"), 80, "75% back, rounded down")
	assert_eq(s.amount(&"wood"), 25)


func test_r59_supply_is_reserved_and_capped() -> void:
	var s := RtsStockpile.new()
	s.max_supply = 20
	s.provide(8)
	assert_true(s.reserve(6))
	assert_false(s.reserve(3), "8 − 6 leaves 2")
	s.provide(30)
	assert_eq(s.supply_free(), 14, "farms can't pass max_supply (20 − 6)")
	s.release(6)
	assert_eq(s.supply_free(), 20)
	s.provide(-40)
	assert_eq(s.supply_cap, 0, "never below 0")
	assert_true(s.can_fit(0), "a free item always fits")


func test_r59_a_dead_worker_frees_its_slot() -> void:
	var n := RtsResourceNode.new(&"gold", 100, 1)
	var dead := Node.new()
	assert_true(n.try_occupy(dead))
	dead.free()
	assert_true(n.try_occupy(RefCounted.new()), "the freed worker's slot is free again, without an error")


func test_r59_a_node_has_slots_and_runs_out() -> void:
	var n := RtsResourceNode.new(&"gold", 25, 2)
	var a := RefCounted.new()
	var b := RefCounted.new()
	var c := RefCounted.new()
	assert_true(n.try_occupy(a))
	assert_true(n.try_occupy(b))
	assert_false(n.try_occupy(c), "the third waits")
	n.release(a)
	assert_true(n.try_occupy(c))
	watch_signals(n)
	assert_eq(n.take(10), 10)
	assert_eq(n.take(10), 10)
	assert_eq(n.take(10), 5, "the last load is what's left")
	assert_signal_emitted(n, "depleted")
	assert_false(n.try_occupy(a), "a spent node takes nobody")


func test_r59_the_gathering_loop_walks_gathers_and_deposits() -> void:
	var stock := RtsStockpile.new()
	var node := RtsResourceNode.new(&"gold", 1000, 2, Vector3(8, 0, 0))
	var g := _gatherer(stock, node, Vector3.ZERO)
	var h := Host.new(g, Vector3.ZERO)
	# One trip: 2 s there (8 m at 4 m/s), 1 s gathering, 2 s back = 5 s per 10 gold.
	_run([h], 4.9)
	assert_eq(stock.amount(&"gold"), 0, "not yet back")
	_run([h], 0.3)
	assert_eq(stock.amount(&"gold"), 10, "the first load is in")
	_run([h], 50.0)
	assert_between(stock.amount(&"gold"), 100, 120, "about one load per 5 s")


func test_r59_income_formula_matches_and_saturates() -> void:
	var predicted := RtsResourceNode.income_per_minute(1, 8.0, 4.0, 1.0, 10, 2)
	assert_almost_eq(predicted, 120.0, 0.01, "10 per 5 s")
	var stock := RtsStockpile.new()
	var node := RtsResourceNode.new(&"gold", 100000, 2, Vector3(2, 0, 0))
	var hosts: Array = []
	for i in 6:
		hosts.append(Host.new(_gatherer(stock, node, Vector3.ZERO), Vector3.ZERO))
	_run(hosts, 60.0)
	var cap := RtsResourceNode.income_per_minute(6, 2.0, 4.0, 1.0, 10, 2)
	assert_almost_eq(cap, 1200.0, 0.01, "2 slots × 10 per 1 s: the node caps six workers at 1200 a minute")
	assert_between(stock.amount(&"gold"), 1050, 1200, "the simulation saturates too (%d)" % stock.amount(&"gold"))
	var two := RtsResourceNode.income_per_minute(2, 2.0, 4.0, 1.0, 10, 2)
	var three := RtsResourceNode.income_per_minute(3, 2.0, 4.0, 1.0, 10, 2)
	assert_gt(two, three * 0.6, "the third worker adds less than a full share")


func test_r59_waiting_for_a_slot() -> void:
	var node := RtsResourceNode.new(&"gold", 1000, 1, Vector3(1, 0, 0))
	var stock := RtsStockpile.new()
	var a := Host.new(_gatherer(stock, node, Vector3.ZERO), Vector3(1, 0, 0))
	var b := Host.new(_gatherer(stock, node, Vector3.ZERO), Vector3(1, 0, 0))
	a.step(0.1)
	b.step(0.1)
	assert_eq(a.g.state, RtsGatherer.State.GATHERING)
	assert_eq(b.g.state, RtsGatherer.State.WAIT, "one slot: the second waits at the node")


func test_r59_moves_on_from_a_spent_node_and_uses_the_nearest_drop() -> void:
	var stock := RtsStockpile.new()
	var first := RtsResourceNode.new(&"wood", 10, 2, Vector3(4, 0, 0))
	var second := RtsResourceNode.new(&"wood", 100, 2, Vector3(0, 0, 4))
	var g := _gatherer(stock, first, Vector3.ZERO)
	g.find_node = func(kind: StringName, _from: Vector3, _busy: RtsResourceNode) -> RtsResourceNode: return second if kind == &"wood" and not second.is_spent() else null
	var drops := [Vector3.ZERO]
	g.find_drop = func(from: Vector3) -> Vector3:
		var best := Vector3.INF
		for d: Vector3 in drops:
			if best == Vector3.INF or from.distance_to(d) < from.distance_to(best):
				best = d
		return best
	var h := Host.new(g, Vector3.ZERO)
	_run([h], 6.0)
	assert_eq(stock.amount(&"wood"), 10, "the first tree gave its 10")
	assert_eq(g.node, second, "then the next tree")
	drops.append(Vector3(0, 0, 5))             # a lumber mill right by the new tree
	var where: Array[Vector3] = []
	g.deposited.connect(func(_k: StringName, _n: int) -> void: where.append(g.position))
	_run([h], 3.5)
	assert_false(where.is_empty(), "it delivered again")
	assert_eq(where[where.size() - 1], Vector3(0, 0, 5), "at the new, nearer drop-off")


func test_r59_a_long_wait_moves_to_another_node() -> void:
	var busy := RtsResourceNode.new(&"wood", 1000, 1, Vector3(1, 0, 0))
	var free := RtsResourceNode.new(&"wood", 1000, 1, Vector3(3, 0, 0))
	busy.try_occupy(RefCounted.new())               # someone is chopping it
	var stock := RtsStockpile.new()
	var g := _gatherer(stock, busy, Vector3.ZERO)
	g.find_node = func(_k: StringName, _from: Vector3, skip: RtsResourceNode) -> RtsResourceNode: return free if skip != free else busy
	var h := Host.new(g, Vector3(1, 0, 0))
	_run([h], 1.0)
	assert_eq(g.state, RtsGatherer.State.WAIT, "it waits a little")
	_run([h], 2.5)
	assert_eq(g.node, free, "then goes to the free tree")
	assert_true(g.state == RtsGatherer.State.GATHERING or g.state == RtsGatherer.State.TO_DROP, "and works")


func test_r59_stop_keeps_the_load() -> void:
	var stock := RtsStockpile.new()
	var node := RtsResourceNode.new(&"gold", 1000, 1, Vector3(1, 0, 0))
	var g := _gatherer(stock, node, Vector3.ZERO)
	var h := Host.new(g, Vector3(1, 0, 0))
	_run([h], 1.1)
	assert_eq(g.carrying, 10)
	g.stop()
	assert_eq(g.state, RtsGatherer.State.IDLE)
	assert_eq(g.carrying, 10, "the load stays")
	assert_true(node.try_occupy(RefCounted.new()), "the slot is free again")
