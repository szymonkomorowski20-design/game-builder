class_name Wallet
extends RefCounted
## Currency + buying/selling against an Inventory (recipe 09). All prices are integers (no float money).

signal balance_changed(balance: int)

var balance: int = 0
var sell_ratio: float = 0.5   ## fraction of the item value paid when the player sells


func _init(start: int = 0) -> void:
	balance = start


func earn(amount: int) -> void:
	if amount > 0:
		balance += amount
		balance_changed.emit(balance)


func spend(amount: int) -> bool:
	if amount <= 0 or amount > balance:
		return false
	balance -= amount
	balance_changed.emit(balance)
	return true


## Buys `count` × item at `price` each. Atomic: no money is taken unless every item fits.
func buy(inv: Inventory, id: StringName, price: int, count: int = 1) -> bool:
	var total := price * count
	if total > balance or count <= 0:
		return false
	var left := inv.add(id, count)
	if left > 0:
		inv.remove(id, count - left)
		return false
	return spend(total)


func sell(inv: Inventory, id: StringName, value: int, count: int = 1) -> bool:
	if not inv.remove(id, count):
		return false
	earn(int(floor(value * sell_ratio)) * count)
	return true
