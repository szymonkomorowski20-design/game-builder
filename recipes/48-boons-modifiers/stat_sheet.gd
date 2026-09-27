class_name StatSheet
extends RefCounted
## Base stats plus modifiers. value(stat) = (base + Σ flat) × (1 + Σ increased) × Π more — the same in any order,
## so a build never depends on the order upgrades were picked. Read stats through value() every time they are used
## (damage on hit, speed each frame); `changed` tells caches and UI when to refresh.

signal changed(stat: StringName)

var base := {}                         ## stat → float
var _mods: Array[StatModifier] = []


func _init(base_stats: Dictionary = {}) -> void:
	base = base_stats.duplicate()


func add(mod: StatModifier) -> void:
	_mods.append(mod)
	changed.emit(mod.stat)


func remove_source(source: StringName) -> void:
	var touched := {}
	for m in _mods:
		if m.source == source:
			touched[m.stat] = true
	_mods = _mods.filter(func(m: StatModifier) -> bool: return m.source != source)
	for stat: StringName in touched:
		changed.emit(stat)


func value(stat: StringName) -> float:
	var flat := 0.0
	var increased := 0.0
	var more := 1.0
	for m in _mods:
		if m.stat != stat:
			continue
		match m.op:
			StatModifier.Op.FLAT:
				flat += m.value
			StatModifier.Op.INCREASED:
				increased += m.value
			StatModifier.Op.MORE:
				more *= m.value
	return (float(base.get(stat, 0.0)) + flat) * (1.0 + increased) * more


func modifiers_from(source: StringName) -> Array[StatModifier]:
	return _mods.filter(func(m: StatModifier) -> bool: return m.source == source)
