class_name Achievements
extends RefCounted
## Stat-driven achievements: the game reports stats ("coins_collected" += 1); achievements unlock when
## their stat reaches a threshold. Unlocks happen once and are saved as a list of ids.

signal unlocked(id: StringName)

var stats: Dictionary = {}       ## StringName -> int
var unlocked_ids: Array = []     ## StringName
var _defs: Array = []            ## {"id", "stat", "target"}


func define(id: StringName, stat: StringName, target: int) -> void:
	_defs.append({"id": id, "stat": stat, "target": target})


func add_stat(stat: StringName, amount: int = 1) -> void:
	stats[stat] = int(stats.get(stat, 0)) + amount
	for d in _defs:
		if d.stat == stat and not unlocked_ids.has(d.id) and stats[stat] >= d.target:
			unlocked_ids.append(d.id)
			unlocked.emit(d.id)


func is_unlocked(id: StringName) -> bool:
	return unlocked_ids.has(id)


func to_dict() -> Dictionary:
	var s := {}
	for k in stats:
		s[String(k)] = stats[k]
	return {"stats": s, "unlocked": unlocked_ids.map(func(x): return String(x))}


func load_dict(d: Dictionary) -> void:
	stats.clear()
	for k in d.get("stats", {}):
		stats[StringName(k)] = int(d.stats[k])
	unlocked_ids = d.get("unlocked", []).map(func(x): return StringName(x))
