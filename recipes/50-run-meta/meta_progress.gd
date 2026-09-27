class_name MetaProgress
extends RefCounted
## What survives between runs: the banked currency and permanent upgrades. Each upgrade adds `per_level` to a stat
## per level (through a StatSheet, source "meta:<id>"); the level n → n+1 costs base_cost × (n + 1). Saved with
## to_dict()/from_dict() through the save recipe (13).

var currency := 0
var upgrades := {}     ## id → {stat, per_level, base_cost, max_level}
var _levels := {}      ## id → level


func bank(amount: int) -> void:
	currency += maxi(amount, 0)


func level(id: StringName) -> int:
	return _levels.get(id, 0)


func cost(id: StringName) -> int:
	return int(upgrades[id].base_cost) * (level(id) + 1)


func can_buy(id: StringName) -> bool:
	return upgrades.has(id) and level(id) < int(upgrades[id].max_level) and currency >= cost(id)


func buy(id: StringName) -> bool:
	if not can_buy(id):
		return false
	currency -= cost(id)
	_levels[id] = level(id) + 1
	return true


func apply_to(sheet: StatSheet) -> void:
	for id: StringName in upgrades:
		var source := StringName("meta:%s" % id)
		sheet.remove_source(source)
		if level(id) == 0:
			continue
		var m := StatModifier.new()
		m.stat = upgrades[id].stat
		m.op = StatModifier.Op.FLAT
		m.value = float(upgrades[id].per_level) * level(id)
		m.source = source
		sheet.add(m)


func to_dict() -> Dictionary:
	var levels := {}
	for id: StringName in _levels:
		levels[String(id)] = _levels[id]
	return {"currency": currency, "levels": levels}


func from_dict(data: Dictionary) -> void:
	currency = int(data.get("currency", 0))
	_levels.clear()
	var levels: Dictionary = data.get("levels", {})
	for id: String in levels:
		_levels[StringName(id)] = int(levels[id])
