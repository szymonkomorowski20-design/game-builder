extends GutTest
## R09 — stacking, overflow returned, all-or-nothing removal, round trip through a dictionary.


func _def(id: StringName, stack: int) -> ItemDef:
	var d := ItemDef.new()
	d.id = id
	d.max_stack = stack
	return d


func _inv(slot_count: int = 3) -> Inventory:
	return Inventory.new(slot_count, [_def(&"potion", 5), _def(&"sword", 1)])


func test_r09_stacks_fill_before_new_slots() -> void:
	var inv := _inv()
	assert_eq(inv.add(&"potion", 3), 0)
	assert_eq(inv.add(&"potion", 4), 0)
	assert_eq(inv.slots[0].count, 5)
	assert_eq(inv.slots[1].count, 2)
	assert_eq(inv.count_of(&"potion"), 7)


func test_r09_overflow_is_returned_not_lost() -> void:
	var inv := _inv(2)
	assert_eq(inv.add(&"potion", 12), 2, "2 slots × 5 = 10 fit, 2 left over")
	assert_eq(inv.add(&"sword", 1), 1, "no free slot")


func test_r09_unstackable_items_take_one_slot_each() -> void:
	var inv := _inv(3)
	assert_eq(inv.add(&"sword", 2), 0)
	assert_eq(inv.slots[0].count, 1)
	assert_eq(inv.slots[1].count, 1)


func test_r09_remove_is_all_or_nothing() -> void:
	var inv := _inv()
	inv.add(&"potion", 7)
	assert_false(inv.remove(&"potion", 8), "not enough → nothing removed")
	assert_eq(inv.count_of(&"potion"), 7)
	assert_true(inv.remove(&"potion", 6))
	assert_eq(inv.count_of(&"potion"), 1)


func test_r09_round_trip_dict() -> void:
	var inv := _inv()
	inv.add(&"potion", 6)
	inv.add(&"sword", 1)
	var copy := _inv()
	copy.load_dict(JSON.parse_string(JSON.stringify(inv.to_dict())))
	assert_eq(copy.count_of(&"potion"), 6)
	assert_eq(copy.count_of(&"sword"), 1)
