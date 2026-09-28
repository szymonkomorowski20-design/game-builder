extends GutTest
## R58 — RTS selection and orders. Selection: a click takes the nearest object within the radius; shift toggles; a click
## on nothing clears; an enemy is selected alone; a box takes own units only, units over buildings, shift adds; the
## limit keeps the first caught; a double-click takes every own unit of that kind on screen; control groups assign,
## add, recall and forget the dead. Orders: the smart right-click (attack an enemy, gather a resource, help build an
## unfinished building, else move); shift queues; STOP replaces; done() advances; PATROL cycles; a dead target ends
## its order.


class Thing:
	extends RefCounted
	var team := 0
	var kind: StringName = &"footman"
	var is_building := false
	var is_resource := false
	var finished := true
	var alive := true
	var pos := Vector2.ZERO

	func _init(p: Vector2, t: int = 0, k: StringName = &"footman", building: bool = false) -> void:
		pos = p
		team = t
		kind = k
		is_building = building


var to_screen := func(c: Object) -> Vector2: return (c as Thing).pos if (c as Thing).pos.x >= 0.0 else Vector2.INF


func _sel() -> RtsSelection:
	var s := RtsSelection.new()
	s.team = 0
	return s


func test_r58_click_takes_the_nearest_within_the_radius() -> void:
	var a := Thing.new(Vector2(100, 100))
	var b := Thing.new(Vector2(110, 100))
	var s := _sel()
	s.click([a, b], Vector2(107, 100), to_screen)
	assert_eq(s.selected, [b] as Array[Object], "the nearer one")
	s.click([a, b], Vector2(500, 500), to_screen)
	assert_true(s.selected.is_empty(), "a click on nothing clears")


func test_r58_shift_click_toggles_and_an_enemy_is_selected_alone() -> void:
	var a := Thing.new(Vector2(100, 100))
	var b := Thing.new(Vector2(200, 100))
	var e := Thing.new(Vector2(300, 100), 1)
	var s := _sel()
	s.click([a, b, e], Vector2(100, 100), to_screen)
	s.click([a, b, e], Vector2(200, 100), to_screen, true)
	assert_eq(s.selected.size(), 2, "shift adds")
	s.click([a, b, e], Vector2(100, 100), to_screen, true)
	assert_eq(s.selected, [b] as Array[Object], "shift on a selected one removes it")
	s.click([a, b, e], Vector2(300, 100), to_screen, true)
	assert_eq(s.selected, [e] as Array[Object], "an enemy never mixes with own units")
	assert_true(s.units().is_empty(), "and it takes no orders")


func test_r58_box_takes_own_units_over_buildings() -> void:
	var u1 := Thing.new(Vector2(10, 10))
	var u2 := Thing.new(Vector2(20, 20))
	var farm := Thing.new(Vector2(30, 30), 0, &"farm", true)
	var enemy := Thing.new(Vector2(15, 15), 1)
	var off := Thing.new(Vector2(-5, 5))
	var s := _sel()
	s.box([u1, u2, farm, enemy, off], Rect2(40, 40, -40, -40), to_screen)    # dragged up-left: a negative rect
	assert_eq(s.selected, [u1, u2] as Array[Object], "own units only, no building, no enemy, nothing off screen")
	s.box([farm], Rect2(0, 0, 50, 50), to_screen)
	assert_eq(s.selected, [farm] as Array[Object], "a box with only a building takes the building")
	var u3 := Thing.new(Vector2(100, 100))
	s.box([u1, u2], Rect2(0, 0, 50, 50), to_screen)
	s.box([u3], Rect2(90, 90, 20, 20), to_screen, true)
	assert_eq(s.selected.size(), 3, "shift adds a box")


func test_r58_limit_keeps_the_first_caught() -> void:
	var s := _sel()
	s.limit = 12
	var many: Array = []
	for i in 20:
		many.append(Thing.new(Vector2(i, 0)))
	s.box(many, Rect2(-1, -1, 100, 10), to_screen)
	assert_eq(s.selected.size(), 12)


func test_r58_double_click_takes_the_kind_on_screen() -> void:
	var a := Thing.new(Vector2(10, 10), 0, &"archer")
	var b := Thing.new(Vector2(500, 10), 0, &"archer")
	var c := Thing.new(Vector2(20, 10), 0, &"footman")
	var far := Thing.new(Vector2(5000, 10), 0, &"archer")
	var s := _sel()
	s.select_same_kind([a, b, c, far], a, Rect2(0, 0, 1280, 720), to_screen)
	assert_eq(s.selected, [a, b] as Array[Object], "every own archer on screen, not the one outside the view")


func test_r58_control_groups() -> void:
	var a := Thing.new(Vector2(10, 10))
	var b := Thing.new(Vector2(20, 10))
	var c := Thing.new(Vector2(30, 10))
	var s := _sel()
	s.box([a, b], Rect2(0, 0, 25, 25), to_screen)
	s.assign_group(1)
	s.click([c], Vector2(30, 10), to_screen)
	s.add_to_group(1)
	s.click([], Vector2.ZERO, to_screen)
	assert_true(s.recall_group(1))
	assert_eq(s.selected, [a, b, c] as Array[Object], "assigned, then added to")
	b.alive = false
	s.prune()
	assert_eq(s.selected, [a, c] as Array[Object], "the dead drop out of the selection")
	assert_eq((s.groups[1] as Array).size(), 2, "and out of the group (its badge counts 2)")
	assert_true(s.recall_group(1))
	assert_eq(s.selected, [a, c] as Array[Object], "and out of the group")
	assert_false(s.recall_group(2), "an empty group selects nothing")
	assert_eq(s.selected.size(), 2, "and keeps the selection")


class Body:
	extends Node3D
	var team := 0
	var kind: StringName = &"footman"
	var is_building := false
	var alive := true


func test_r58_a_freed_unit_leaves_the_selection_and_groups() -> void:
	var a := Body.new()
	var b := Body.new()
	var s := _sel()
	var at := func(o: Object) -> Vector2: return Vector2(10, 10) if o == a else Vector2(20, 10)
	s.box([a, b], Rect2(0, 0, 50, 50), at)
	s.assign_group(3)
	b.free()
	s.prune()
	assert_eq(s.selected, [a] as Array[Object], "the freed one is gone, without an error")
	assert_eq((s.groups[3] as Array).size(), 1, "and from the group")
	assert_eq(s.units(), [a] as Array[Object])
	a.free()


func test_r58_changed_fires_only_on_a_change() -> void:
	var a := Thing.new(Vector2(10, 10))
	var s := _sel()
	watch_signals(s)
	s.click([a], Vector2(10, 10), to_screen)
	s.click([a], Vector2(10, 10), to_screen)
	assert_signal_emit_count(s, "changed", 1)


func test_r58_smart_order() -> void:
	var enemy := Thing.new(Vector2.ZERO, 1)
	var gold := Thing.new(Vector2.ZERO, -1, &"gold_mine")
	gold.is_resource = true
	var site := Thing.new(Vector2.ZERO, 0, &"farm", true)
	site.finished = false
	var ground := Vector3(5, 0, 5)
	assert_eq(RtsOrders.smart(0, true, true, enemy, ground).kind, RtsOrders.Kind.ATTACK)
	assert_eq(RtsOrders.smart(0, true, true, gold, ground).kind, RtsOrders.Kind.GATHER, "a worker gathers")
	assert_eq(RtsOrders.smart(0, false, false, gold, ground).kind, RtsOrders.Kind.MOVE, "a soldier walks to it")
	assert_eq(RtsOrders.smart(0, true, true, site, ground).kind, RtsOrders.Kind.BUILD, "a worker helps build")
	site.finished = true
	assert_eq(RtsOrders.smart(0, true, true, site, ground).kind, RtsOrders.Kind.MOVE, "a finished one: just walk there")
	assert_eq(RtsOrders.smart(0, true, true, null, ground).at, ground)
	enemy.alive = false
	assert_eq(RtsOrders.smart(0, true, true, enemy, ground).kind, RtsOrders.Kind.MOVE, "a dead enemy is ground")


func test_r58_queue_shift_stop_patrol() -> void:
	var o := RtsOrders.new()
	o.give(RtsOrders.make(RtsOrders.Kind.MOVE, Vector3(1, 0, 0)))
	o.give(RtsOrders.make(RtsOrders.Kind.MOVE, Vector3(2, 0, 0)), true)
	o.give(RtsOrders.make(RtsOrders.Kind.ATTACK_MOVE, Vector3(3, 0, 0)), true)
	assert_eq(o.queue.size(), 3, "shift queues")
	o.done()
	assert_eq(o.current().at, Vector3(2, 0, 0), "done → the next")
	o.give(RtsOrders.make(RtsOrders.Kind.MOVE, Vector3(9, 0, 0)))
	assert_eq(o.queue.size(), 1, "without shift a new order replaces the queue")
	o.give(RtsOrders.make(RtsOrders.Kind.STOP), true)
	assert_eq(o.current().kind, RtsOrders.Kind.STOP, "STOP replaces even with shift")
	o.give(RtsOrders.make(RtsOrders.Kind.PATROL, Vector3(0, 0, 0)))
	o.give(RtsOrders.make(RtsOrders.Kind.PATROL, Vector3(10, 0, 0)), true)
	o.done()
	o.done()
	assert_eq(o.current().at, Vector3(0, 0, 0), "a patrol goes back and forth")
	assert_false(o.idle())


func test_r58_a_freed_target_ends_its_order_without_an_error() -> void:
	var tree := Node3D.new()                     # a depleted tree, freed by the game
	var o := RtsOrders.new()
	o.give(RtsOrders.make(RtsOrders.Kind.GATHER, Vector3.ZERO, tree))
	o.give(RtsOrders.make(RtsOrders.Kind.MOVE, Vector3(4, 0, 0)), true)
	tree.free()
	assert_eq(o.current().kind, RtsOrders.Kind.MOVE, "the gather is over; the queued move follows")
	var gone := Node3D.new()
	gone.free()
	assert_eq(RtsOrders.smart(0, true, true, gone, Vector3(1, 0, 1)).kind, RtsOrders.Kind.MOVE, "a right click on a freed thing is a move")


func test_r58_a_dead_target_ends_its_order() -> void:
	var enemy := Thing.new(Vector2.ZERO, 1)
	var o := RtsOrders.new()
	o.give(RtsOrders.make(RtsOrders.Kind.ATTACK, Vector3.ZERO, enemy))
	o.give(RtsOrders.make(RtsOrders.Kind.MOVE, Vector3(4, 0, 0)), true)
	enemy.alive = false
	assert_eq(o.current().kind, RtsOrders.Kind.MOVE, "the attack is over; the queued move follows")
	o.done()
	assert_true(o.idle())
