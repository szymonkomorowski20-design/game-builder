extends GutTest
## R60 — building placement, production and the tech tree. Grid: snapping to the footprint's centre, fitting only
## inside the map on free, unblocked, explored cells (with the reason), placing and removing, a no-build ring.
## Production: paid when queued, the queue limit, supply reserved at the start (blocked once, then it starts when a farm
## frees supply), produced in order after its time, cancel refunds (and releases started supply). Tech tree: needs,
## what is missing, and losing a building locks again.


func test_r60_grid_snaps_to_the_footprint_centre() -> void:
	var g := RtsBuildGrid.new()
	g.cell_size = 2.0
	var cell := g.footprint_at(Vector3(10.2, 0, 10.9), Vector2i(2, 2))
	assert_eq(cell, Vector2i(4, 4))
	assert_eq(g.centre(cell, Vector2i(2, 2)), Vector3(10, 0, 10), "a 2×2 centres on a cell corner")
	var c3 := g.footprint_at(Vector3(10.2, 0, 10.9), Vector2i(3, 3))
	assert_eq(g.centre(c3, Vector2i(3, 3)), Vector3(11, 0, 11), "a 3×3 centres on the nearest cell middle")
	assert_eq(g.cell_of(Vector3(-0.5, 0, 3.9)), Vector2i(-1, 1))


func test_r60_grid_fits_only_where_it_may() -> void:
	var g := RtsBuildGrid.new()
	g.width = 10
	g.height = 10
	assert_eq(g.why_not(Vector2i(8, 8), Vector2i(3, 3)), "outside")
	assert_true(g.place(Vector2i(2, 2), Vector2i(2, 2), 1))
	assert_eq(g.why_not(Vector2i(3, 3), Vector2i(2, 2)), "occupied")
	assert_false(g.place(Vector2i(3, 3), Vector2i(2, 2), 2), "an overlap takes nothing")
	assert_false(g.occupied.has(Vector2i(4, 4)))
	g.blocked[Vector2i(6, 6)] = true
	assert_eq(g.why_not(Vector2i(5, 5), Vector2i(2, 2)), "blocked")
	g.explored = func(c: Vector2i) -> bool: return c.x < 8
	assert_eq(g.why_not(Vector2i(7, 0), Vector2i(2, 2)), "unexplored")
	g.remove(1)
	assert_true(g.can_place(Vector2i(3, 3), Vector2i(2, 2)), "a removed building frees its cells")


func test_r60_no_build_ring() -> void:
	var g := RtsBuildGrid.new()
	g.block_around(Vector2i(10, 10), Vector2i(2, 2), 3)
	assert_eq(g.why_not(Vector2i(13, 13), Vector2i(1, 1)), "blocked", "inside the ring")
	assert_true(g.can_place(Vector2i(15, 15), Vector2i(1, 1)), "outside the ring")


func _production(gold: int, supply_cap: int) -> RtsProduction:
	var s := RtsStockpile.new({&"gold": gold})
	s.provide(supply_cap)
	var p := RtsProduction.new()
	p.stockpile = s
	return p


func _footman() -> Dictionary:
	return RtsProduction.item(&"footman", {&"gold": 100}, 2, 3.0)


func test_r60_paid_when_queued_and_limited() -> void:
	var p := _production(1000, 20)
	p.max_queue = 3
	assert_true(p.enqueue(_footman()))
	assert_eq(p.stockpile.amount(&"gold"), 900, "paid at once")
	assert_true(p.enqueue(_footman()))
	assert_true(p.enqueue(_footman()))
	assert_false(p.enqueue(_footman()), "the queue is full")
	assert_eq(p.stockpile.amount(&"gold"), 700, "and the refused one cost nothing")
	var poor := _production(50, 20)
	assert_false(poor.enqueue(_footman()), "can't pay")


func test_r60_produces_in_order_after_its_time() -> void:
	var p := _production(1000, 20)
	p.enqueue(_footman())
	p.enqueue(RtsProduction.item(&"archer", {&"gold": 120}, 1, 2.0))
	var out: Array[StringName] = []
	p.produced.connect(func(id: StringName) -> void: out.append(id))
	for i in 29:
		p.tick(0.1)
	assert_true(out.is_empty(), "not before 3 s")
	p.tick(0.15)
	assert_eq(out, [&"footman"] as Array[StringName])
	for i in 21:
		p.tick(0.1)
	assert_eq(out, [&"footman", &"archer"] as Array[StringName])
	assert_eq(p.stockpile.supply_used, 3, "their supply stays used (they are alive)")


func test_r60_supply_blocked_waits_then_starts() -> void:
	var p := _production(1000, 3)
	p.enqueue(_footman())
	p.enqueue(_footman())
	watch_signals(p)
	for i in 31:
		p.tick(0.1)
	assert_signal_emit_count(p, "produced", 1)
	for i in 50:
		p.tick(0.1)
	assert_true(p.is_blocked(), "the second waits: 2 + 2 > 3")
	assert_signal_emit_count(p, "blocked", 1, "said once, not every frame")
	assert_almost_eq(p.fraction(), 0.0, 0.001)
	p.stockpile.provide(8)
	for i in 31:
		p.tick(0.1)
	assert_signal_emit_count(p, "produced", 2, "a farm later, it starts")


func test_r60_cancel_refunds_and_releases() -> void:
	var p := _production(300, 20)
	p.enqueue(_footman())
	p.enqueue(_footman())
	p.tick(1.0)
	assert_eq(p.stockpile.supply_used, 2, "the front one started")
	assert_true(p.cancel(0))
	assert_eq(p.stockpile.amount(&"gold"), 200, "the full cost back")
	assert_eq(p.stockpile.supply_used, 0, "and its supply")
	assert_almost_eq(p.fraction(), 0.0, 0.001, "the next starts from zero")
	assert_true(p.cancel())
	assert_eq(p.stockpile.amount(&"gold"), 300)
	assert_false(p.cancel(), "nothing left")


func test_r60_tech_tree() -> void:
	var t := RtsTechTree.new({&"barracks": [&"town_hall"], &"knight": [&"blacksmith", &"stable"]})
	assert_false(t.available(&"barracks"))
	t.add(&"town_hall")
	assert_true(t.available(&"barracks"))
	t.add(&"stable")
	assert_eq(t.missing(&"knight"), [&"blacksmith"] as Array[StringName], "the tooltip's 'Needs: …'")
	t.add(&"blacksmith")
	t.add(&"blacksmith")
	assert_true(t.available(&"knight"))
	t.remove(&"blacksmith")
	assert_true(t.available(&"knight"), "one blacksmith is left")
	t.remove(&"blacksmith")
	assert_false(t.available(&"knight"), "losing the last one locks knights again")
	assert_true(t.available(&"footman"), "no needs: always available")
