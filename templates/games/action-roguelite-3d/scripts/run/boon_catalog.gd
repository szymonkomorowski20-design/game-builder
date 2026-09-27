class_name BoonCatalog
extends RefCounted
## The template's boons, written as data in one place (move them to .tres files when a designer takes over).
## Tags are the "schools": speed, power, guard, fire. Synergies need a boon of each of their required tags.
## Values are for COMMON; recipe 48 scales them by rarity.

const BURNING_BLADE := &"burning_blade"


static func all() -> Array[Boon]:
	return [
		_make(&"swift_feet", "Swift Feet", "+20% move speed", [&"speed"], [], &"speed", StatModifier.Op.INCREASED, 0.20),
		_make(&"heavy_blows", "Heavy Blows", "+25% damage", [&"power"], [], &"attack_power", StatModifier.Op.INCREASED, 0.25),
		_make(&"thick_hide", "Thick Hide", "+20 max health", [&"guard"], [], &"max_health", StatModifier.Op.FLAT, 20.0),
		_make(&"keen_edge", "Keen Edge", "+0.15 damage multiplier", [&"power"], [], &"attack_power", StatModifier.Op.FLAT, 0.15),
		_make(BURNING_BLADE, "Burning Blade", "hits set enemies on fire (2 dmg / 0.5 s for 2 s)", [&"fire"], [], &"burn_power", StatModifier.Op.FLAT, 1.0),
		_make(&"momentum", "Momentum", "damage ×1.2 — needs speed + power", [&"speed", &"power"], [&"speed", &"power"], &"attack_power", StatModifier.Op.MORE, 1.2),
		_make(&"bulwark", "Bulwark", "max health ×1.25 — needs guard + power", [&"guard", &"power"], [&"guard", &"power"], &"max_health", StatModifier.Op.MORE, 1.25),
	]


static func pool() -> BoonPool:
	var p := BoonPool.new()
	p.boons = all()
	return p


static func _make(id: StringName, title: String, text: String, tags: Array[StringName], requires: Array[StringName], stat: StringName, op: StatModifier.Op, value: float) -> Boon:
	var m := StatModifier.new()
	m.stat = stat
	m.op = op
	m.value = value
	var b := Boon.new()
	b.id = id
	b.title = title
	b.description = text
	b.tags = tags
	b.requires_tags = requires
	b.modifiers = [m]
	return b
