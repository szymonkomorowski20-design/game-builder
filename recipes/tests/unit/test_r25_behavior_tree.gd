extends GutTest
## R25 — priorities (selector), sequences stop on failure, RUNNING actions resume, inverter.

var did: Array = []


func _guard_tree() -> BT.Task:
	return BT.Selector.new([
		BT.Sequence.new([
			BT.Condition.new(func(bb): return bb.sees_player),
			BT.Action.new(func(_bb): did.append("attack"); return true),
		]),
		BT.Sequence.new([
			BT.Condition.new(func(bb): return bb.hp < 3),
			BT.Action.new(func(_bb): did.append("flee"); return true),
		]),
		BT.Action.new(func(_bb): did.append("patrol"); return true),
	])


func before_each() -> void:
	did = []


func test_r25_highest_priority_branch_wins() -> void:
	var t := _guard_tree()
	t.tick({"sees_player": true, "hp": 1})
	t.tick({"sees_player": false, "hp": 1})
	t.tick({"sees_player": false, "hp": 10})
	assert_eq(did, ["attack", "flee", "patrol"])


func test_r25_running_action_resumes_without_rechecking_earlier_children() -> void:
	var checks := [0]
	var steps := [0]
	var seq := BT.Sequence.new([
		BT.Condition.new(func(_bb): checks[0] += 1; return true),
		BT.Action.new(func(_bb): steps[0] += 1; return BT.RUNNING if steps[0] < 3 else BT.SUCCESS),
	])
	assert_eq(seq.tick({}), BT.RUNNING)
	assert_eq(seq.tick({}), BT.RUNNING)
	assert_eq(seq.tick({}), BT.SUCCESS)
	assert_eq(checks[0], 1, "condition evaluated once while the action was running")
	seq.tick({})
	assert_eq(checks[0], 2, "restarts from the first child after finishing")


func test_r25_inverter() -> void:
	var yes := BT.Condition.new(func(_bb): return true)
	assert_eq(BT.Inverter.new(yes).tick({}), BT.FAILURE)
