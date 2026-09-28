extends GutTest
## The skirmish's numbers as contracts (scripts/core/rts_rules.gd): every unit and building is complete and reachable
## through the tech tree, the counter triangle holds on a balance sheet at equal cost (small, medium and large armies),
## a worker pays for itself quickly, the opening build is affordable, buildings can be razed but not by a lone worker,
## and the supply ceiling is reachable. The engine versions of these live in scenarios R2, R4, R5, R9.

const BUDGETS := [420, 720, 1260]
const WIN_MARGIN := 0.25            ## the counter keeps at least this share of its budget alive


func _rules() -> RtsRules:
	return load("res://data/rules.tres") as RtsRules


func _combat(r: RtsRules) -> RtsCombat:
	var c := RtsCombat.new()
	c.table = r.type_table
	return c


func _body(def: Dictionary) -> Dictionary:
	return {"armour": def.armour, "armour_type": def.armour_type, "tags": def.get("tags", [])}


func _cost(def: Dictionary) -> int:
	var n := 0
	for k in def.cost:
		n += int(def.cost[k])
	return n


## A balance-sheet fight: equal budgets, everyone focuses the first enemy alive, the longer-ranged side fires alone
## while the other closes the range gap. Returns the share of each side's budget still alive.
func _fight(r: RtsRules, a_kind: StringName, b_kind: StringName, budget: int) -> Vector2:
	var c := _combat(r)
	var a := r.unit(a_kind)
	var b := r.unit(b_kind)
	var sides: Array = [[], []]
	for i in budget / _cost(a):
		sides[0].append({"hp": float(a.hp), "cd": 0.0})
	for i in budget / _cost(b):
		sides[1].append({"hp": float(b.hp), "cd": 0.0})
	var defs := [a, b]
	var hit := [c.damage(a.attack, _body(b)), c.damage(b.attack, _body(a))]
	var head := [maxf(0.0, (a.range - b.range) / b.speed), maxf(0.0, (b.range - a.range) / a.speed)]
	var t := 0.0
	var dt := 0.05
	while _alive(sides[0]) > 0 and _alive(sides[1]) > 0 and t < 300.0:
		for s in 2:
			var foe: Array = sides[1 - s]
			if t < head[1 - s]:
				continue                 # still closing the range gap
			for u: Dictionary in sides[s]:
				if u.hp <= 0.0:
					continue
				u.cd -= dt
				if u.cd > 0.0:
					continue
				for v: Dictionary in foe:
					if v.hp > 0.0:
						v.hp -= hit[s]
						u.cd = defs[s].cooldown
						break
		t += dt
	return Vector2(_alive(sides[0]) * _cost(a) / float(budget), _alive(sides[1]) * _cost(b) / float(budget))


func _alive(side: Array) -> int:
	return side.filter(func(u: Dictionary) -> bool: return u.hp > 0.0).size()


func test_every_unit_and_building_is_complete() -> void:
	var r := _rules()
	for kind in r.units:
		var d: Dictionary = r.units[kind]
		for key in ["cost", "supply", "time", "hp", "armour", "armour_type", "attack", "range", "cooldown", "speed", "sight", "radius"]:
			assert_true(d.has(key), "unit %s has %s" % [kind, key])
		assert_true(r.type_table.has(d.attack.type), "unit %s attacks with a type in the table" % kind)
		var trained_by := r.buildings.keys().filter(func(b: StringName) -> bool: return (r.buildings[b].trains as Array).has(kind))
		assert_eq(trained_by.size(), 1, "unit %s is trained by exactly one building" % kind)
	for kind in r.buildings:
		var d: Dictionary = r.buildings[kind]
		for need in d.needs:
			assert_true(r.buildings.has(need), "building %s needs %s, which exists" % [kind, need])
		for row in r.type_table.values():
			assert_true((row as Dictionary).has(d.armour_type), "every attack type has a multiplier for %s" % d.armour_type)


func test_the_tech_tree_opens_in_order() -> void:
	var tree := RtsTechTree.new(_rules().tech_table())
	assert_true(tree.available(&"farm") and tree.available(&"town_hall"), "farm and town hall need nothing")
	assert_false(tree.available(&"barracks"), "no barracks without a town hall")
	tree.add(&"town_hall")
	assert_true(tree.available(&"worker") and tree.available(&"barracks"), "a town hall opens workers and the barracks")
	assert_false(tree.available(&"archer") or tree.available(&"stable"), "… but not archers or the stable")
	tree.add(&"barracks")
	assert_true(tree.available(&"footman") and tree.available(&"archer") and tree.available(&"stable"), "a barracks opens footmen, archers, the stable")
	assert_false(tree.available(&"rider"), "no riders without a stable")
	tree.add(&"stable")
	assert_true(tree.available(&"rider"), "a stable opens riders")


func test_the_counter_triangle_at_equal_cost() -> void:
	var r := _rules()
	for pair in [[&"archer", &"footman"], [&"rider", &"archer"], [&"footman", &"rider"]]:
		for budget: int in BUDGETS:
			var left := _fight(r, pair[0], pair[1], budget)
			assert_gt(left.x, WIN_MARGIN, "%s beat %s at %d gold (keep %.2f of the budget)" % [pair[0], pair[1], budget, left.x])
			assert_eq(left.y, 0.0, "… and wipe them out")


func test_the_bonuses_point_along_the_triangle() -> void:
	var r := _rules()
	for pair in [[&"footman", &"rider"], [&"rider", &"archer"]]:
		var bonus: Dictionary = r.unit(pair[0]).attack.get("bonus", {})
		var prey_tags: Array = r.unit(pair[1]).get("tags", [])
		var hits := bonus.keys().filter(func(tag: StringName) -> bool: return prey_tags.has(tag))
		assert_eq(hits.size(), 1, "%s has a bonus against a tag %s carries" % [pair[0], pair[1]])
		if hits.size() == 1:
			assert_gte(float(bonus[hits[0]]), float(r.unit(pair[0]).attack.damage) / 3.0, "… worth at least a third of its hit")


func test_a_worker_pays_for_itself_quickly() -> void:
	var w := _rules().unit(&"worker")
	var trip: float = 2.0 * 6.0 / w.speed + w.gather_time              # a mine 6 m from the drop-off
	var per_second: float = w.carry / trip
	assert_lt(w.cost[&"gold"] / per_second, 30.0, "a worker earns back its gold in under 30 s")


func test_the_opening_is_affordable_and_fits() -> void:
	var r := _rules()
	var bank := RtsStockpile.new(r.start)
	assert_true(bank.spend(r.building(&"farm").cost) and bank.spend(r.building(&"barracks").cost), "the start bank pays a farm and a barracks")
	assert_lte(r.start_workers, int(r.building(&"town_hall").supply), "the start workers fit the town hall's food")
	var farms := ceili(float(r.max_supply - int(r.building(&"town_hall").supply)) / float(r.building(&"farm").supply))
	assert_lte(farms, 20, "the supply ceiling is reachable (%d farms)" % farms)


func test_buildings_fall_to_an_army_not_to_a_worker() -> void:
	var r := _rules()
	var c := _combat(r)
	var dps := func(unit: StringName, building: StringName) -> float:
		var u := r.unit(unit)
		return c.damage(u.attack, _body(r.building(building))) / float(u.cooldown)
	assert_lt(r.building(&"town_hall").hp / (10.0 * dps.call(&"footman", &"town_hall")), 60.0, "ten footmen raze a town hall within a minute")
	assert_lt(r.building(&"farm").hp / (5.0 * dps.call(&"footman", &"farm")), 20.0, "five footmen raze a farm within 20 s")
	assert_gt(r.building(&"town_hall").hp / dps.call(&"worker", &"town_hall"), 300.0, "a lone worker cannot raze a town hall in five minutes")
