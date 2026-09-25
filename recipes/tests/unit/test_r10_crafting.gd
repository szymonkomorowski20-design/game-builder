extends GutTest
## R10 — crafting consumes inputs and adds the output; insufficient inputs or no room → nothing changes.

const BANDAGE := {"id": &"bandage", "inputs": {&"cloth": 2, &"herb": 1}, "output": &"bandage", "amount": 1}


func _inv(slots: int) -> Inventory:
	var defs: Array = []
	for id in [&"cloth", &"herb", &"bandage"]:
		var d := ItemDef.new()
		d.id = id
		d.max_stack = 10
		defs.append(d)
	return Inventory.new(slots, defs)


func test_r10_craft_consumes_and_produces() -> void:
	var inv := _inv(4)
	inv.add(&"cloth", 3)
	inv.add(&"herb", 1)
	assert_true(Crafting.craft(inv, BANDAGE))
	assert_eq(inv.count_of(&"cloth"), 1)
	assert_eq(inv.count_of(&"herb"), 0)
	assert_eq(inv.count_of(&"bandage"), 1)


func test_r10_missing_inputs_change_nothing() -> void:
	var inv := _inv(4)
	inv.add(&"cloth", 1)
	inv.add(&"herb", 1)
	assert_false(Crafting.craft(inv, BANDAGE))
	assert_eq(inv.count_of(&"cloth"), 1)
	assert_eq(inv.count_of(&"herb"), 1)


func test_r10_no_room_for_output_rolls_back() -> void:
	# One slot holding a full stack of cloth; consuming 1 cloth does not free the slot.
	var tight := _inv(1)
	tight.add(&"cloth", 10)
	var needs_new_slot := {"id": &"x", "inputs": {&"cloth": 1}, "output": &"bandage", "amount": 1}
	assert_false(Crafting.craft(tight, needs_new_slot), "output needs a slot the inventory does not have")
	assert_eq(tight.count_of(&"cloth"), 10, "inputs restored after the failed craft")
	assert_eq(tight.count_of(&"bandage"), 0)
