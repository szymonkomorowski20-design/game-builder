class_name QuestLog
extends RefCounted
## Quests as data with counted objectives. The game reports events ("killed:slime", "picked:herb");
## active quests advance, complete once, and survive save/load.
##   define(&"herbs", [{"event": "picked:herb", "count": 5}]); start(&"herbs"); report("picked:herb")

signal quest_started(id: StringName)
signal objective_progress(id: StringName, index: int, value: int, target: int)
signal quest_completed(id: StringName)

enum Status { LOCKED, ACTIVE, COMPLETED }

var _defs: Dictionary = {}       ## id -> Array of objectives
var status: Dictionary = {}      ## id -> Status
var progress: Dictionary = {}    ## id -> Array[int]


func define(id: StringName, objectives: Array) -> void:
	_defs[id] = objectives
	status[id] = Status.LOCKED
	progress[id] = objectives.map(func(_o): return 0)


func start(id: StringName) -> bool:
	if status.get(id, -1) != Status.LOCKED:
		return false
	status[id] = Status.ACTIVE
	quest_started.emit(id)
	return true


func report(event: String, amount: int = 1) -> void:
	for id in _defs:
		if status[id] != Status.ACTIVE:
			continue
		var objs: Array = _defs[id]
		for i in objs.size():
			if objs[i].event == event and progress[id][i] < int(objs[i].count):
				progress[id][i] = mini(progress[id][i] + amount, int(objs[i].count))
				objective_progress.emit(id, i, progress[id][i], int(objs[i].count))
		if _all_done(id):
			status[id] = Status.COMPLETED
			quest_completed.emit(id)


func _all_done(id: StringName) -> bool:
	var objs: Array = _defs[id]
	for i in objs.size():
		if progress[id][i] < int(objs[i].count):
			return false
	return true


func to_dict() -> Dictionary:
	var out := {}
	for id in _defs:
		out[String(id)] = {"status": status[id], "progress": progress[id]}
	return out


func load_dict(d: Dictionary) -> void:
	for key in d:
		var id := StringName(key)
		if not _defs.has(id):
			continue   # quest removed in a newer version — ignore instead of crashing
		status[id] = int(d[key].status)
		var saved: Array = d[key].progress
		for i in mini(saved.size(), progress[id].size()):
			progress[id][i] = int(saved[i])
