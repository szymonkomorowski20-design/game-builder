extends GutTest
## R11 — buying needs money and room (atomic), selling pays the ratio, no negative balance.


func _inv(slots: int) -> Inventory:
	var d := ItemDef.new()
	d.id = &"potion"
	d.max_stack = 5
	return Inventory.new(slots, [d])


func test_r11_buy_takes_money_and_adds_items() -> void:
	var w := Wallet.new(100)
	var inv := _inv(2)
	assert_true(w.buy(inv, &"potion", 15, 3))
	assert_eq(w.balance, 55)
	assert_eq(inv.count_of(&"potion"), 3)


func test_r11_cannot_buy_without_money() -> void:
	var w := Wallet.new(10)
	var inv := _inv(2)
	assert_false(w.buy(inv, &"potion", 15, 1))
	assert_eq(w.balance, 10)
	assert_eq(inv.count_of(&"potion"), 0)


func test_r11_buy_without_room_keeps_money_and_inventory() -> void:
	var w := Wallet.new(1000)
	var inv := _inv(1)
	assert_false(w.buy(inv, &"potion", 10, 7), "only 5 fit")
	assert_eq(w.balance, 1000)
	assert_eq(inv.count_of(&"potion"), 0, "partial adds rolled back")


func test_r11_sell_pays_ratio_rounded_down() -> void:
	var w := Wallet.new(0)
	var inv := _inv(1)
	inv.add(&"potion", 2)
	assert_true(w.sell(inv, &"potion", 15, 2))
	assert_eq(w.balance, 14, "floor(15 × 0.5) × 2")
	assert_false(w.sell(inv, &"potion", 15, 1), "nothing left to sell")


func test_r11_spend_rejects_overdraft_and_negative() -> void:
	var w := Wallet.new(5)
	assert_false(w.spend(6))
	assert_false(w.spend(-1))
	assert_eq(w.balance, 5)
