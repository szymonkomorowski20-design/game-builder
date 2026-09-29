extends GutTest
## Recipe 69 — guard alert states on a shared board: a noise is stared at, investigated by one guard and dropped; one
## investigator per stimulus; stimulus priorities; detection calls for support only after the call delay (and a
## silenced guard never calls); nearby guards answer an alarm, far ones don't; a lost player is followed for the memory
## time, then the last seen place is searched (hidden points first, ticked off) and the guard calms down with caution;
## the search's time limit and the searcher cap; a body raises an alarm and a search.

const HERE := Vector3.ZERO


func _sense(level := 0, seen := false, at := Vector3.ZERO, true_pos := Vector3.ZERO) -> Dictionary:
	return {level = level, seen = seen, seen_at = at, true_pos = true_pos}


func test_r69_noise_is_checked_and_dropped() -> void:
	var g := GuardBrain.new(AlertBoard.new(), HERE)
	g.notice(&"noise", "n1", Vector3(10, 0, 0), 0.0)
	g.tick(0.0, _sense(), HERE)
	assert_eq(g.state, GuardBrain.State.SUSPICIOUS, "a noise: stop and stare")
	assert_eq(g.look_at, Vector3(10, 0, 0), "at the noise")
	g.tick(0.5, _sense(), HERE)
	assert_eq(g.state, GuardBrain.State.SUSPICIOUS, "for the whole turn time")
	g.tick(1.0, _sense(), HERE)
	assert_eq(g.state, GuardBrain.State.INVESTIGATE, "then walk over")
	assert_eq(g.goal, Vector3(10, 0, 0), "to the noise")
	assert_false(g.running, "walking: a cautious check")
	g.tick(2.0, _sense(), Vector3(9.5, 0, 0))
	g.tick(3.9, _sense(), Vector3(9.5, 0, 0))
	assert_eq(g.state, GuardBrain.State.INVESTIGATE, "looking around at the spot")
	g.tick(4.0, _sense(), Vector3(9.5, 0, 0))
	assert_eq(g.state, GuardBrain.State.RETURN, "nothing there: back to the post")
	g.tick(5.0, _sense(), Vector3(0.3, 0, 0))
	assert_eq(g.state, GuardBrain.State.PATROL, "and on patrol again")
	assert_true(g.stimulus().is_empty(), "the noise is forgotten")


func test_r69_one_investigator_per_stimulus() -> void:
	var board := AlertBoard.new()
	var a := GuardBrain.new(board, HERE)
	var b := GuardBrain.new(board, Vector3(2, 0, 0))
	for g: GuardBrain in [a, b]:
		g.notice(&"distraction", "stone", Vector3(10, 0, 0), 0.0)
		g.tick(0.0, _sense(), HERE)
	a.tick(1.0, _sense(), HERE)
	b.tick(1.0, _sense(), Vector3(2, 0, 0))
	assert_eq(a.state, GuardBrain.State.INVESTIGATE, "the first guard checks")
	assert_eq(b.state, GuardBrain.State.RETURN, "the second stays: a distraction pulls one guard")


func test_r69_priorities() -> void:
	var g := GuardBrain.new(AlertBoard.new(), HERE)
	g.notice(&"distraction", "a", Vector3(1, 0, 0), 0.0)
	g.notice(&"noise", "b", Vector3(2, 0, 0), 1.0)
	assert_eq(g.stimulus().key, "a", "a lower priority doesn't replace a higher one")
	g.notice(&"distraction", "c", Vector3(3, 0, 0), 2.0)
	assert_eq(g.stimulus().key, "c", "on equal priority the newest wins")
	g.notice(&"terror", "d", Vector3(4, 0, 0), 3.0)
	assert_eq(g.stimulus().key, "d", "a higher one replaces it")


func test_r69_call_for_support_and_answers() -> void:
	var board := AlertBoard.new()
	var g := GuardBrain.new(board, HERE)
	var near := GuardBrain.new(board, Vector3(10, 0, 0))
	var far := GuardBrain.new(board, Vector3(100, 0, 0))
	g.tick(0.0, _sense(AwarenessMeter.DETECTED, true, Vector3(5, 0, 5)), HERE)
	assert_eq(g.state, GuardBrain.State.ALERT, "detected: alert")
	assert_true(g.running, "running at the player")
	assert_eq(board.last_known, Vector3(5, 0, 5), "the board knows where the player was seen")
	g.tick(1.0, _sense(AwarenessMeter.DETECTED, true, Vector3(5, 0, 5)), HERE)
	assert_eq(board.alarm_id, 0, "no call yet: silence the guard now and nobody comes")
	g.tick(1.5, _sense(AwarenessMeter.DETECTED, true, Vector3(5, 0, 5)), HERE)
	assert_eq(board.alarm_id, 1, "after the call delay the call is out")
	near.tick(1.6, _sense(), Vector3(10, 0, 0))
	far.tick(1.6, _sense(), Vector3(100, 0, 0))
	assert_eq(near.state, GuardBrain.State.ALERT, "a guard within the alarm radius answers")
	assert_eq(near.goal, Vector3(5, 0, 5), "running to where the player was seen")
	assert_eq(far.state, GuardBrain.State.PATROL, "a far one doesn't")
	g.tick(2.0, _sense(AwarenessMeter.DETECTED, true, Vector3(5, 0, 5)), HERE)
	assert_eq(board.alarm_id, 1, "one call per alert")


func test_r69_memory_last_seen_and_search() -> void:
	var board := AlertBoard.new()
	var g := GuardBrain.new(board, HERE)
	var hidden := Vector3(8, 0, 0)
	g.search_candidates = [Vector3(6, 0, 1), hidden, Vector3(40, 0, 0)] as Array[Vector3]
	g.hidden_from = func(_from: Vector3, p: Vector3) -> bool: return p == hidden
	g.tick(0.0, _sense(AwarenessMeter.DETECTED, true, Vector3(5, 0, 0)), HERE)
	g.tick(1.0, _sense(AwarenessMeter.DETECTED, false, Vector3.ZERO, Vector3(7, 0, 2)), HERE)
	assert_eq(g.goal, Vector3(7, 0, 2), "just lost: the guard still knows where the player is")
	g.tick(3.0, _sense(AwarenessMeter.DETECTED, false, Vector3.ZERO, Vector3(9, 0, 9)), HERE)
	assert_eq(g.goal, Vector3(5, 0, 0), "after the memory: only the last seen place")
	g.tick(4.0, _sense(AwarenessMeter.DETECTED), Vector3(5, 0, 0))
	assert_eq(g.state, GuardBrain.State.SEARCH, "at the last seen place: search")
	g.tick(4.1, _sense(AwarenessMeter.DETECTED), Vector3(5, 0, 0))
	assert_eq(g.goal, hidden, "the place hidden from the last seen spot first, though a visible one is nearer")
	assert_true(g.running, "an aggressive search runs")
	g.tick(5.0, _sense(AwarenessMeter.DETECTED), hidden)
	g.tick(5.1, _sense(AwarenessMeter.DETECTED), hidden)
	assert_eq(g.goal, Vector3(6, 0, 1), "then the next point; the far one is outside the search radius")
	g.tick(6.0, _sense(AwarenessMeter.DETECTED), Vector3(6, 0, 1))
	g.tick(6.1, _sense(AwarenessMeter.DETECTED), Vector3(6, 0, 1))
	assert_eq(g.state, GuardBrain.State.RETURN, "no points left: calm down")
	assert_true(g.wants_reset, "the host resets the awareness meter")
	assert_eq(g.guard_state(10.0), &"caution", "with raised caution")
	assert_eq(g.guard_state(6.1 + g.caution_time + 1.0), &"", "for a while")
	assert_eq(board.searchers(), 0, "the search is left")


func test_r69_search_time_and_cap() -> void:
	var board := AlertBoard.new()
	board.max_searchers = 2
	var many: Array[Vector3] = []
	for i in 20:
		many.append(Vector3(i, 0, 3))
	var guards: Array[GuardBrain] = []
	for i in 3:
		var g := GuardBrain.new(board, HERE)
		g.search_candidates = many
		g.tick(0.0, _sense(AwarenessMeter.DETECTED, true, Vector3(5, 0, 0)), HERE)
		g.tick(3.0, _sense(AwarenessMeter.DETECTED), Vector3(5, 0, 0))
		guards.append(g)
	assert_eq(guards[0].state, GuardBrain.State.SEARCH, "the first searcher")
	assert_eq(guards[1].state, GuardBrain.State.SEARCH, "the second")
	assert_eq(guards[2].state, GuardBrain.State.RETURN, "the third is over the cap: back to the post")
	guards[0].tick(3.1, _sense(AwarenessMeter.DETECTED), Vector3(5, 0, 0))
	guards[1].tick(3.1, _sense(AwarenessMeter.DETECTED), Vector3(5, 0, 0))
	assert_ne(guards[0].goal, guards[1].goal, "two searchers never take the same point")
	guards[0].tick(3.0 + guards[0].search_time, _sense(AwarenessMeter.DETECTED), Vector3(5, 0, 0))
	assert_eq(guards[0].state, GuardBrain.State.RETURN, "the search ends after search_time")


func test_r69_body_raises_alarm_and_search() -> void:
	var board := AlertBoard.new()
	var g := GuardBrain.new(board, HERE)
	g.search_candidates = [Vector3(5, 0, 2)] as Array[Vector3]
	g.notice(&"body", "body1", Vector3(4, 0, 0), 0.0)
	g.tick(0.0, _sense(), HERE)
	g.tick(1.0, _sense(), HERE)
	assert_eq(g.state, GuardBrain.State.INVESTIGATE, "a body is checked")
	g.tick(2.0, _sense(), Vector3(4, 0, 0))
	assert_eq(board.alarm_id, 1, "found: alarm")
	assert_eq(g.state, GuardBrain.State.SEARCH, "and a search around it")


func test_r69_resighted_during_search() -> void:
	var board := AlertBoard.new()
	var g := GuardBrain.new(board, HERE)
	g.search_candidates = [Vector3(8, 0, 0)] as Array[Vector3]
	g.tick(0.0, _sense(AwarenessMeter.DETECTED, true, Vector3(5, 0, 0)), HERE)
	g.tick(3.0, _sense(AwarenessMeter.DETECTED), Vector3(5, 0, 0))
	assert_eq(g.state, GuardBrain.State.SEARCH, "searching")
	g.tick(3.5, _sense(AwarenessMeter.SUSPICIOUS, true, Vector3(9, 0, 1)), Vector3(6, 0, 0))
	assert_eq(g.state, GuardBrain.State.ALERT, "seen again while searching: straight back to the chase")
	assert_eq(g.goal, Vector3(9, 0, 1), "at the player")
