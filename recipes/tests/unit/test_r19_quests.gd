extends GutTest
## R19 — only active quests progress, progress caps at the target, completion fires once, save round trip,
## unknown quests in old saves are ignored.


func _log() -> QuestLog:
	var q := QuestLog.new()
	q.define(&"herbs", [{"event": "picked:herb", "count": 3}])
	q.define(&"hunt", [{"event": "killed:slime", "count": 2}, {"event": "killed:boss", "count": 1}])
	return q


func test_r19_locked_quest_ignores_events() -> void:
	var q := _log()
	q.report("picked:herb")
	assert_eq(q.progress[&"herbs"][0], 0)


func test_r19_progress_caps_and_completes_once() -> void:
	var q := _log()
	watch_signals(q)
	q.start(&"herbs")
	q.report("picked:herb", 2)
	assert_eq(q.status[&"herbs"], QuestLog.Status.ACTIVE)
	q.report("picked:herb", 5)
	assert_eq(q.progress[&"herbs"][0], 3)
	assert_eq(q.status[&"herbs"], QuestLog.Status.COMPLETED)
	q.report("picked:herb")
	assert_signal_emit_count(q, "quest_completed", 1)


func test_r19_all_objectives_required() -> void:
	var q := _log()
	q.start(&"hunt")
	q.report("killed:slime", 2)
	assert_eq(q.status[&"hunt"], QuestLog.Status.ACTIVE, "boss still alive")
	q.report("killed:boss")
	assert_eq(q.status[&"hunt"], QuestLog.Status.COMPLETED)


func test_r19_round_trip_and_unknown_quest() -> void:
	var q := _log()
	q.start(&"hunt")
	q.report("killed:slime")
	var data: Dictionary = JSON.parse_string(JSON.stringify(q.to_dict()))
	data["removed_quest"] = {"status": 1, "progress": [4]}
	var r := _log()
	r.load_dict(data)
	assert_eq(r.status[&"hunt"], QuestLog.Status.ACTIVE)
	assert_eq(r.progress[&"hunt"], [1, 0])
	assert_false(r.status.has(&"removed_quest"))
