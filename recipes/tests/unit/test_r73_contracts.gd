extends GutTest
## Recipe 73 — viewpoints reveal the markers in their radius once and become fast-travel points, and show nearby
## viewpoints; walking up to a marker reveals it too. A target's routine is a deterministic loop of stops and walks.
## A contract goes approach → escape → done; detection alerts the target but fails nothing; only a target reaching
## safety or the player's death fail it; bonuses never do.


func _network() -> ViewpointNetwork:
	var n := ViewpointNetwork.new()
	n.add_viewpoint(&"tower", Vector3(0, 20, 0), 40.0)
	n.add_viewpoint(&"belfry", Vector3(70, 25, 0), 40.0)
	n.add_viewpoint(&"far_mill", Vector3(200, 10, 0), 40.0)
	n.add_marker(&"target_house", Vector3(30, 0, 10), &"contract")
	n.add_marker(&"hay_1", Vector3(-10, 0, 5), &"hideout")
	n.add_marker(&"market", Vector3(60, 0, 0), &"shop")
	return n


func test_r73_viewpoint_reveals_once() -> void:
	var n := _network()
	var fresh := n.sync(&"tower")
	assert_eq(fresh.size(), 2, "the markers within 40 m, at once")
	assert_true(fresh.has(&"hay_1") and fresh.has(&"target_house"), "the hideout and the target's house, not the market")
	n.add_marker(&"later_contract", Vector3(5, 0, 5), &"contract")
	assert_true(n.sync(&"tower").is_empty(), "a viewpoint syncs once: syncing again reveals nothing, even a new marker")
	assert_eq(n.fast_travel_points(), [&"tower"] as Array[StringName], "a synced viewpoint is a fast-travel point")
	assert_eq(n.seen_unsynced(), [&"belfry"] as Array[StringName], "the next viewpoint within reach shows on the map")
	assert_eq(n.discover_near(Vector3(58, 0, 0), 5.0), [&"market"] as Array[StringName], "walking up to a place reveals it too")
	assert_eq(n.revealed().size(), 3, "three known now")


func test_r73_routine_is_a_deterministic_loop() -> void:
	var r := TargetRoutine.new()
	r.speed = 1.0
	r.add_stop(Vector3(0, 0, 0), 3.0)
	r.add_stop(Vector3(4, 0, 0), 2.0)
	r.add_stop(Vector3(4, 0, 3), 0.0)
	assert_almost_eq(r.loop_time(), 3.0 + 4.0 + 2.0 + 3.0 + 0.0 + 5.0, 1e-5, "waits and walks, back to the start")
	assert_eq(r.position_at(1.0), Vector3(0, 0, 0), "waiting at the first stop")
	assert_eq(r.waiting_at(1.0), 0, "the first stop")
	assert_almost_eq(r.position_at(5.0), Vector3(2, 0, 0), Vector3.ONE * 1e-5, "halfway to the second")
	assert_eq(r.waiting_at(5.0), -1, "walking")
	assert_eq(r.position_at(8.0), Vector3(4, 0, 0), "waiting at the second")
	assert_almost_eq(r.position_at(10.5), Vector3(4, 0, 1.5), Vector3.ONE * 1e-5, "on to the third")
	assert_almost_eq(r.position_at(12.0 + 2.5), Vector3(4, 0, 3).lerp(Vector3.ZERO, 0.5), Vector3.ONE * 1e-5, "and back")
	assert_almost_eq(r.position_at(5.0 + r.loop_time()), r.position_at(5.0), Vector3.ONE * 1e-4, "the same place a loop later")


func test_r73_contract_detection_changes_not_fails() -> void:
	var c := Contract.new(&"merchant")
	c.start(0.0)
	assert_eq(c.phase, Contract.Phase.APPROACH, "find the target")
	c.on_detected()
	assert_eq(c.phase, Contract.Phase.APPROACH, "detected: nothing fails")
	assert_true(c.target_alerted, "but the target runs for safety")
	c.on_kill(false)
	assert_eq(c.phase, Contract.Phase.APPROACH, "a guard killed on the way: still on")
	c.on_kill(true)
	assert_eq(c.phase, Contract.Phase.ESCAPE, "the target is down: escape")
	c.on_target_safe()
	assert_eq(c.phase, Contract.Phase.ESCAPE, "a dead target can't reach safety")
	c.on_escaped(95.0)
	assert_eq(c.phase, Contract.Phase.DONE, "the chase lost: done")
	assert_eq(c.bonuses(), {unseen = false, only_the_target = false}, "bonuses reported, not required")


func test_r73_contract_fails_only_two_ways() -> void:
	var safe := Contract.new(&"a")
	safe.start(0.0)
	safe.on_target_safe()
	assert_eq(safe.phase, Contract.Phase.FAILED, "the target reached safety")
	var died := Contract.new(&"b")
	died.start(0.0)
	died.on_kill(true)
	died.on_player_died()
	assert_eq(died.phase, Contract.Phase.FAILED, "the player died while escaping")
	var clean := Contract.new(&"c")
	clean.start(0.0)
	clean.on_kill(true)
	clean.on_escaped(40.0)
	assert_eq(clean.bonuses(), {unseen = true, only_the_target = true}, "a clean contract earns both bonuses")
	clean.on_player_died()
	assert_eq(clean.phase, Contract.Phase.DONE, "nothing after the end changes it")
