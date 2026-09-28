class_name RtsStockpile
extends RefCounted
## One team's resources and supply (recipe 59). Resources: any kinds (gold, wood…). Spending is all-or-nothing, so a
## cost of {gold 120, wood 40} never takes the gold and fails on the wood. Supply (food): units use it, houses / farms
## provide it up to `max_supply`; production reserves it when an item starts (the genre's rule), so two barracks can't
## both start the last footman that fits.

signal changed

var amounts := {}                    ## kind → amount
var supply_used := 0
var supply_cap := 0
var max_supply := 100                ## the ceiling no number of farms can pass


func _init(start: Dictionary = {}) -> void:
	amounts = start.duplicate()


func amount(kind: StringName) -> int:
	return int(amounts.get(kind, 0))


func add(kind: StringName, n: int) -> void:
	if n == 0:
		return
	amounts[kind] = amount(kind) + n
	changed.emit()


func can_afford(cost: Dictionary) -> bool:
	for k in cost:
		if amount(k) < int(cost[k]):
			return false
	return true


## Takes the whole cost, or nothing. Returns whether it did.
func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for k in cost:
		amounts[k] = amount(k) - int(cost[k])
	changed.emit()
	return true


## Gives back `fraction` of a cost (a cancelled item: 1.0; a cancelled building site: often 0.75), rounded down.
func refund(cost: Dictionary, fraction: float = 1.0) -> void:
	for k in cost:
		amounts[k] = amount(k) + floori(int(cost[k]) * fraction)
	changed.emit()


## The supply that can still be used.
func supply_free() -> int:
	return mini(supply_cap, max_supply) - supply_used


func can_fit(supply: int) -> bool:
	return supply <= 0 or supply_free() >= supply


## Reserves supply for an item that starts (production) — false when it does not fit.
func reserve(supply: int) -> bool:
	if not can_fit(supply):
		return false
	supply_used += supply
	changed.emit()
	return true


## A unit died or an item was cancelled: its supply is free again.
func release(supply: int) -> void:
	supply_used = maxi(supply_used - supply, 0)
	changed.emit()


## A house / farm finished (+n) or destroyed (−n). Units above the cap stay; nothing new starts until it fits.
func provide(n: int) -> void:
	supply_cap = maxi(supply_cap + n, 0)
	changed.emit()
