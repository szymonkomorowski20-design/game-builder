extends GutTest
## Recipe 72 — notoriety and the chase: levels from the value, acts seen by a guard count at once and by a civilian only
## after the report (unless the witness is stopped), posters and heralds, optional decay, named effects per level; the
## search circle at the last seen place, escape by leaving it or by hiding, and being seen again.


func test_r72_levels_and_acts() -> void:
	var n := Notoriety.new()
	assert_eq(n.level(), 0, "unknown")
	n.witnessed(&"fight", true, 0.0)
	n.witnessed(&"trespass", true, 0.0)
	assert_eq(n.level(), 1, "a fight and a trespass seen by guards: level 1 (25)")
	n.witnessed(&"kill", true, 0.0)
	assert_eq(n.level(), 2, "a kill: level 2 (55)")
	n.witnessed(&"kill", true, 0.0)
	assert_eq(n.level(), 3, "another: level 3 (85)")
	n.witnessed(&"kill", true, 0.0)
	assert_eq(n.value, 100.0, "capped at 100")


func test_r72_witness_reports_can_be_stopped() -> void:
	var n := Notoriety.new()
	var id := n.witnessed(&"kill", false, 10.0)
	assert_gt(id, 0, "a civilian saw it: a report is on its way")
	n.tick(15.9, 0.1)
	assert_eq(n.value, 0.0, "not yet reported")
	n.tick(16.0, 0.1)
	assert_eq(n.value, 30.0, "reported after report_time")
	var stopped := n.witnessed(&"kill", false, 20.0)
	assert_true(n.stop_witness(stopped), "the witness is stopped in time")
	n.tick(30.0, 0.1)
	assert_eq(n.value, 30.0, "and reports nothing")
	assert_eq(n.pending_reports(), 0, "no report left pending")


func test_r72_lowering() -> void:
	var n := Notoriety.new()
	n.value = 70.0
	n.tear_poster()
	assert_eq(n.value, 45.0, "a poster takes 25")
	n.bribe_herald()
	assert_eq(n.value, 22.5, "a herald halves it")
	n.tick(100.0, 60.0)
	assert_eq(n.value, 22.5, "no passive decay by default")
	n.decay_per_s = 0.5
	n.tick(101.0, 10.0)
	assert_eq(n.value, 17.5, "with decay switched on")


func test_r72_effects_rise_with_the_level() -> void:
	var n := Notoriety.new()
	var last := 0.0
	for v in [0.0, 30.0, 60.0, 90.0]:
		n.value = v
		var e := n.effect()
		assert_gt(float(e.notice), last, "guards notice faster at each level (%d)" % n.level())
		last = float(e.notice)
		assert_eq(e.attack_on_sight, n.level() == 3, "attack on sight only at the top level")
	n.value = 60.0
	assert_true(n.effect().roof_guards, "guards on the roofs from level 2")


func test_r72_escape_by_leaving_the_circle() -> void:
	var w := WantedSearch.new()
	w.seen(Vector3(0, 0, 0), 0.0, 1)
	assert_eq(w.tick(0.2, Vector3(1, 0, 0), false), WantedSearch.State.SEEN, "seen: the chase")
	assert_eq(w.tick(0.6, Vector3(3, 0, 0), false), WantedSearch.State.LOST, "out of sight: lost, a circle stays")
	assert_eq(w.radius, 20.0, "20 m at level 1")
	assert_eq(w.tick(10.0, Vector3(15, 0, 0), false), WantedSearch.State.LOST, "inside the circle: still searched for")
	w.tick(11.0, Vector3(25, 0, 0), false)
	assert_eq(w.tick(14.9, Vector3(26, 0, 0), false), WantedSearch.State.LOST, "just out: not yet")
	w.tick(15.0, Vector3(10, 0, 0), false)
	assert_eq(w.tick(19.5, Vector3(26, 0, 0), false), WantedSearch.State.LOST, "back in and out again: the timer restarts")
	assert_eq(w.tick(23.5, Vector3(27, 0, 0), false), WantedSearch.State.ESCAPED, "4 s out of the circle: escaped")
	assert_false(w.is_chased(), "the chase is over")


func test_r72_escape_by_hiding_and_being_seen_again() -> void:
	var w := WantedSearch.new()
	w.seen(Vector3(0, 0, 0), 0.0, 3)
	assert_eq(w.radius, 40.0, "40 m at level 3")
	w.tick(1.0, Vector3(2, 0, 0), false)
	w.tick(2.0, Vector3(2, 0, 0), true)
	w.seen(Vector3(2, 0, 0), 3.0, 3)
	assert_eq(w.tick(3.1, Vector3(2, 0, 0), true), WantedSearch.State.SEEN, "seen while hiding: the chase is back")
	assert_eq(w.tick(4.0, Vector3(2, 0, 0), true), WantedSearch.State.LOST, "out of sight again")
	w.tick(4.1, Vector3(2, 0, 0), true)
	assert_eq(w.tick(7.0, Vector3(2, 0, 0), true), WantedSearch.State.LOST, "the hiding timer started over: 2.9 s")
	assert_eq(w.tick(7.1, Vector3(2, 0, 0), true), WantedSearch.State.ESCAPED, "3 s hidden: escaped")
