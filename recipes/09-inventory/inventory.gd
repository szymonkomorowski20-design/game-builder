class_name Inventory
extends RefCounted
## Slot inventory with stacking. Pure data (no nodes) so it is trivially testable and serialisable.
## `add` returns what did NOT fit — the caller decides whether to drop it on the ground.

signal changed

var slots: Array = []       ## each: {"id": StringName, "count": int} or null
var _defs: Dictionary = {}  ## id -> ItemDef


func _init(slot_count: int = 12, defs: Array = []) -> void:
	slots.resize(slot_count)
	for d: ItemDef in defs:
		_defs[d.id] = d


func register(def: ItemDef) -> void:
	_defs[def.id] = def


func max_stack(id: StringName) -> int:
	return (_defs[id] as ItemDef).max_stack if _defs.has(id) else 1


## Adds `count` of `id`; fills existing stacks first, then empty slots. Returns the leftover.
func add(id: StringName, count: int) -> int:
	if count <= 0:
		return 0
	var left := count
	var cap := max_stack(id)
	for i in slots.size():
		var s = slots[i]
		if s != null and s.id == id and s.count < cap:
			var put := mini(cap - s.count, left)
			s.count += put
			left -= put
			if left == 0:
				break
	for i in slots.size():
		if left == 0:
			break
		if slots[i] == null:
			var put := mini(cap, left)
			slots[i] = {"id": id, "count": put}
			left -= put
	if left != count:
		changed.emit()
	return left


func count_of(id: StringName) -> int:
	var n := 0
	for s in slots:
		if s != null and s.id == id:
			n += s.count
	return n


## Removes `count` of `id` if available (all or nothing). Returns true on success.
func remove(id: StringName, count: int) -> bool:
	if count <= 0 or count_of(id) < count:
		return false
	var left := count
	for i in range(slots.size() - 1, -1, -1):
		var s = slots[i]
		if s != null and s.id == id:
			var take := mini(s.count, left)
			s.count -= take
			left -= take
			if s.count == 0:
				slots[i] = null
			if left == 0:
				break
	changed.emit()
	return true


func to_dict() -> Dictionary:
	var out: Array = []
	for s in slots:
		out.append(null if s == null else {"id": String(s.id), "count": s.count})
	return {"slots": out}


func load_dict(d: Dictionary) -> void:
	var src: Array = d.get("slots", [])
	slots.resize(maxi(slots.size(), src.size()))
	for i in slots.size():
		var s = src[i] if i < src.size() else null
		slots[i] = null if s == null else {"id": StringName(s.id), "count": int(s.count)}
	changed.emit()
