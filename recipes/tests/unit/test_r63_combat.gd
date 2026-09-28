extends GutTest
## R63 — RTS combat. Damage: bonus against tags before armour, the type table, flat armour with a 0.5 floor; hits to
## kill and a counter triangle as a contract (each type beats one and loses to one). Targets: whoever attacks me first,
## then the nearest unit, buildings last, nothing out of range or unseen, and the current target kept.


func _combat() -> RtsCombat:
	var c := RtsCombat.new()
	# A counter triangle: blades beat light, arrows beat heavy... as data the game owns.
	c.table = {
		&"blade": {&"light": 1.5, &"heavy": 0.75, &"fortified": 0.5},
		&"pierce": {&"light": 0.75, &"heavy": 1.5, &"fortified": 0.35},
		&"siege": {&"light": 0.5, &"heavy": 0.5, &"fortified": 1.5},
	}
	return c


func test_r63_bonus_then_multiplier_then_armour_with_a_floor() -> void:
	var c := _combat()
	var spear := {"damage": 10.0, "type": &"pierce", "bonus": {&"mounted": 8.0}}
	var knight := {"armour": 2.0, "armour_type": &"heavy", "tags": [&"mounted"]}
	assert_almost_eq(c.damage(spear, knight), (10.0 + 8.0) * 1.5 - 2.0, 0.001, "bonus before armour, times the table")
	var peasant := {"armour": 0.0, "armour_type": &"light", "tags": []}
	assert_almost_eq(c.damage(spear, peasant), 7.5, 0.001, "no bonus, the light multiplier")
	var wall := {"armour": 20.0, "armour_type": &"fortified"}
	assert_almost_eq(c.damage(spear, wall), 0.5, 0.001, "never below the floor")
	assert_almost_eq(RtsCombat.new().damage({"damage": 6.0}, {"armour": 1.0}), 5.0, 0.001, "no table: × 1")


func test_r63_the_counter_triangle_as_a_contract() -> void:
	var c := _combat()
	var hp := 100.0
	var units := {
		&"swordsman": {"attack": {"damage": 12.0, "type": &"blade"}, "body": {"armour": 1.0, "armour_type": &"heavy"}},
		&"archer": {"attack": {"damage": 10.0, "type": &"pierce"}, "body": {"armour": 0.0, "armour_type": &"light"}},
		&"catapult": {"attack": {"damage": 40.0, "type": &"siege"}, "body": {"armour": 1.0, "armour_type": &"fortified"}},
	}
	var hits := func(a: StringName, b: StringName) -> int:
		return c.hits_to_kill(units[a].attack, units[b].body, hp)
	assert_lt(hits.call(&"swordsman", &"archer"), hits.call(&"archer", &"swordsman"), "a swordsman kills an archer in fewer hits than the other way round")
	assert_lt(hits.call(&"archer", &"swordsman"), hits.call(&"swordsman", &"swordsman"), "arrows hurt heavy armour more than blades do")
	assert_lt(hits.call(&"catapult", &"catapult"), hits.call(&"archer", &"catapult"), "siege breaks the fortified; arrows barely scratch it")


class Dummy:
	extends RefCounted


func test_r63_target_priority() -> void:
	var near_unit := Dummy.new()
	var far_unit := Dummy.new()
	var shooter := Dummy.new()
	var tower := Dummy.new()
	var hidden := Dummy.new()
	var c := [
		{"node": tower, "at": Vector3(1, 0, 0), "is_building": true},
		{"node": near_unit, "at": Vector3(3, 0, 0)},
		{"node": far_unit, "at": Vector3(6, 0, 0)},
		{"node": hidden, "at": Vector3(0.5, 0, 0), "visible": false},
	]
	assert_eq(RtsCombat.pick_target(Vector3.ZERO, 8.0, c), near_unit, "the nearest unit, not the nearer tower or the unseen one")
	c.append({"node": shooter, "at": Vector3(7, 0, 0), "attacking_me": true})
	assert_eq(RtsCombat.pick_target(Vector3.ZERO, 8.0, c), shooter, "whoever attacks me first")
	assert_eq(RtsCombat.pick_target(Vector3.ZERO, 8.0, c, far_unit), far_unit, "keeps its current target while valid")
	assert_eq(RtsCombat.pick_target(Vector3.ZERO, 2.0, c), tower, "only the tower is in range: then the tower")
	assert_null(RtsCombat.pick_target(Vector3.ZERO, 0.4, c), "nothing in range")


func test_r63_freed_candidates_and_current_are_skipped() -> void:
	var gone := Node3D.new()
	var here := Dummy.new()
	var c := [{"node": gone, "at": Vector3(1, 0, 0)}, {"node": here, "at": Vector3(3, 0, 0)}]
	gone.free()
	assert_eq(RtsCombat.pick_target(Vector3.ZERO, 8.0, c, gone), here, "a freed target and a freed current are skipped without an error")


func test_r63_leash() -> void:
	assert_false(RtsCombat.should_give_up(Vector3.ZERO, Vector3(5, 0, 0), 8.0))
	assert_true(RtsCombat.should_give_up(Vector3.ZERO, Vector3(9, 0, 0), 8.0))
