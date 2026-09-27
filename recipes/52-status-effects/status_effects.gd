class_name StatusEffects
extends RefCounted
## The statuses on one character. tick(delta) deals damage over time through `damaged` (route it to Health) and ends
## statuses on time through `expired`; stat changes go through the character's StatSheet (recipe 48) while a status
## lasts, so speed/damage read the right value without special cases.

signal damaged(amount: int, id: StringName)
signal applied(id: StringName, stacks: int)
signal expired(id: StringName)

var sheet: StatSheet
var _active := {}   # id → {def, stacks, left, tick_t}


func _init(stat_sheet: StatSheet = null) -> void:
	sheet = stat_sheet


func apply(def: StatusDef, stacks: int = 1) -> void:
	var s: Dictionary = _active.get(def.id, {})
	if s.is_empty():
		s = {"def": def, "stacks": 0, "left": 0.0, "tick_t": 0.0}
		_active[def.id] = s
	if def.stacking == StatusDef.Stacking.STACK:
		s.stacks = mini(s.stacks + stacks, def.max_stacks)
	else:
		s.stacks = 1
	s.left = def.duration
	_apply_modifiers(def, s.stacks)
	applied.emit(def.id, s.stacks)


func has(id: StringName) -> bool:
	return _active.has(id)


func stacks(id: StringName) -> int:
	return _active[id].stacks if _active.has(id) else 0


func tick(delta: float) -> void:
	for id: StringName in _active.keys():
		var s: Dictionary = _active[id]
		var def: StatusDef = s.def
		var step := minf(delta, s.left)
		if def.tick_interval > 0.0:
			s.tick_t += step
			while s.tick_t + 1e-4 >= def.tick_interval:
				s.tick_t -= def.tick_interval
				damaged.emit(def.damage_per_tick * s.stacks, id)
		s.left -= delta
		if s.left <= 1e-4:
			_end(id)


func cleanse() -> void:
	for id: StringName in _active.keys():
		_end(id)


func _end(id: StringName) -> void:
	_active.erase(id)
	if sheet != null:
		sheet.remove_source(_source(id))
	expired.emit(id)


func _apply_modifiers(def: StatusDef, stack_count: int) -> void:
	if sheet == null or def.modifiers.is_empty():
		return
	var source := _source(def.id)
	sheet.remove_source(source)       # re-applying replaces, never doubles
	for m in def.modifiers:
		var scaled := m.duplicate() as StatModifier
		scaled.source = source
		if m.op != StatModifier.Op.MORE:
			scaled.value = m.value * stack_count
		sheet.add(scaled)


static func _source(id: StringName) -> StringName:
	return StringName("status:%s" % id)
