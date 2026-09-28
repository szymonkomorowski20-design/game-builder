class_name RtsRules
extends Resource
## Every gameplay number of the skirmish, in one place (the spec's Tuning table points here; `data/rules.tres` may
## override any of them). Units and buildings are data, as the genre learned early (genre doc §3).
## A unit: cost, supply, time (s), hp, armour, armour_type, tags, attack {damage, type, bonus}, range, cooldown,
## speed (m/s), sight (m), radius (m); a worker also carry, gather_time, build_rate.
## A building: cost, time (s to build), hp, armour, armour_type, size (cells), supply (+), sight, drop_off, trains,
## needs (the tech tree).

@export var start := {&"gold": 400, &"wood": 150}
@export var start_workers := 4
@export var max_supply := 100
@export var cell_size := 2.0

@export var units := {
	&"worker": {
		"cost": {&"gold": 50}, "supply": 1, "time": 8.0, "hp": 40.0, "armour": 0.0, "armour_type": &"light",
		"tags": [], "attack": {"damage": 4.0, "type": &"blade"}, "range": 1.0, "cooldown": 1.2,
		"speed": 3.6, "sight": 7.0, "radius": 0.35, "carry": 10, "gather_time": 1.5, "build_rate": 1.0,
	},
	&"footman": {
		"cost": {&"gold": 90}, "supply": 2, "time": 14.0, "hp": 110.0, "armour": 2.0, "armour_type": &"heavy",
		"tags": [], "attack": {"damage": 10.0, "type": &"blade", "bonus": {&"mounted": 8.0}}, "range": 1.2,
		"cooldown": 1.2, "speed": 3.0, "sight": 8.0, "radius": 0.45,
	},
	&"archer": {
		"cost": {&"gold": 70, &"wood": 30}, "supply": 2, "time": 14.0, "hp": 70.0, "armour": 0.0,
		"armour_type": &"light", "tags": [&"ranged"], "attack": {"damage": 11.0, "type": &"pierce"}, "range": 7.5,
		"cooldown": 1.25, "speed": 3.2, "sight": 10.0, "radius": 0.4,
	},
	&"rider": {
		"cost": {&"gold": 120, &"wood": 20}, "supply": 3, "time": 18.0, "hp": 150.0, "armour": 1.0,
		"armour_type": &"medium", "tags": [&"mounted"], "attack": {"damage": 12.0, "type": &"blade", "bonus": {&"ranged": 6.0}},
		"range": 1.3, "cooldown": 1.2, "speed": 5.0, "sight": 10.0, "radius": 0.6,
	},
}

@export var buildings := {
	&"town_hall": {
		"cost": {&"gold": 400, &"wood": 200}, "time": 60.0, "hp": 1500.0, "armour": 2.0, "armour_type": &"fortified",
		"size": Vector2i(4, 4), "supply": 10, "sight": 12.0, "drop_off": true, "trains": [&"worker"], "needs": [],
	},
	&"farm": {
		"cost": {&"wood": 60}, "time": 20.0, "hp": 300.0, "armour": 0.0, "armour_type": &"fortified",
		"size": Vector2i(2, 2), "supply": 6, "sight": 6.0, "drop_off": false, "trains": [], "needs": [],
	},
	&"barracks": {
		"cost": {&"gold": 160, &"wood": 60}, "time": 35.0, "hp": 700.0, "armour": 1.0, "armour_type": &"fortified",
		"size": Vector2i(3, 3), "supply": 0, "sight": 8.0, "drop_off": false, "trains": [&"footman", &"archer"],
		"needs": [&"town_hall"],
	},
	&"stable": {
		"cost": {&"gold": 150, &"wood": 100}, "time": 35.0, "hp": 600.0, "armour": 1.0, "armour_type": &"fortified",
		"size": Vector2i(3, 3), "supply": 0, "sight": 8.0, "drop_off": false, "trains": [&"rider"],
		"needs": [&"barracks"],
	},
}

## Attack type → armour type → multiplier (recipe 63). The counter triangle: archers (pierce) beat heavy footmen,
## riders (blade, +6 vs ranged) beat archers, footmen (+8 vs mounted) beat riders.
@export var type_table := {
	&"blade": {&"light": 1.25, &"medium": 1.0, &"heavy": 0.8, &"fortified": 0.7},
	&"pierce": {&"light": 1.0, &"medium": 0.8, &"heavy": 2.0, &"fortified": 0.4},
}

@export var resources := {
	&"gold": {"amount": 5000, "slots": 2},
	&"wood": {"amount": 450, "slots": 2},      # 300 ran out by minute 9 in the proof game and bot games stalled
}


func unit(kind: StringName) -> Dictionary:
	return units.get(kind, {})


func building(kind: StringName) -> Dictionary:
	return buildings.get(kind, {})


func is_unit(kind: StringName) -> bool:
	return units.has(kind)


## The tech tree (recipe 60) from `needs`.
func tech_table() -> Dictionary:
	var t := {}
	for b in buildings:
		t[b] = buildings[b].get("needs", [])
	for u in units:
		var needs: Array[StringName] = []
		for b in buildings:
			if (buildings[b].get("trains", []) as Array).has(u):
				needs.append(b)
		t[u] = needs.slice(0, 1)
	return t


## What a unit or building costs, as a power estimate (the AI's `power`).
func value(kind: StringName) -> float:
	var c: Dictionary = units.get(kind, buildings.get(kind, {})).get("cost", {})
	var v := 0.0
	for k in c:
		v += float(c[k])
	return v
