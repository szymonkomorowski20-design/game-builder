class_name MeleeStage
extends RefCounted
## Who may fight the player, and who may strike now (recipe 71, genre doc §11), after Kingdoms of Amalur's stage
## manager:
## - `slots` places around the player; a fighter takes one by its weight within `grid_capacity` (a troll weighs as much
##   as two soldiers), and the rest wait outside, facing free slots, which flanks the player for free;
## - a strike takes its weight from `attack_capacity` and gives it back the moment it lands (or is blocked, countered
##   or interrupted), so attackers take turns;
## - a cooldown per fighter and a short global one keep tells from piling up;
## - difficulty only raises the two capacities.
## Recipe 49's AttackTokens is the one-number version of this; use this one when enemies differ in size.

var slots := 8
var grid_capacity := 12
var attack_capacity := 4
var fighter_cooldown := 1.5
var global_cooldown := 0.35

var _slot_of := {}
var _weight := {}
var _attacking := {}
var _last_attack := {}
var _last_any := -INF


## A slot index for `fighter` (the same one if it has one), or -1 when the grid is full: then wait outside.
func engage(fighter: Object, weight: int) -> int:
	var id := fighter.get_instance_id()
	if _slot_of.has(id):
		return _slot_of[id]
	if engaged_weight() + weight > grid_capacity:
		return -1
	var taken: Array = _slot_of.values()
	for i in slots:
		if not taken.has(i):
			_slot_of[id] = i
			_weight[id] = weight
			return i
	return -1


func disengage(fighter: Object) -> void:
	var id := fighter.get_instance_id()
	_slot_of.erase(id)
	_weight.erase(id)
	_attacking.erase(id)


## True (and the capacity taken) when an engaged `fighter` may start a strike of `weight` now.
func may_attack(fighter: Object, weight: int, now: float) -> bool:
	var id := fighter.get_instance_id()
	if not _slot_of.has(id) or _attacking.has(id):
		return false
	if now - float(_last_attack.get(id, -INF)) < fighter_cooldown or now - _last_any < global_cooldown:
		return false
	if attacking_weight() + weight > attack_capacity:
		return false
	_attacking[id] = weight
	_last_attack[id] = now
	_last_any = now
	return true


## The strike landed, was blocked, countered or interrupted: its capacity is free for the next attacker.
func attack_done(fighter: Object) -> void:
	_attacking.erase(fighter.get_instance_id())


func engaged_weight() -> int:
	var w := 0
	for v: int in _weight.values():
		w += v
	return w


func attacking_weight() -> int:
	var w := 0
	for v: int in _attacking.values():
		w += v
	return w


## Where slot `index` stands around `centre`, `radius` away (slot 0 in front along −Z, clockwise from above).
func slot_position(index: int, centre: Vector3, radius: float) -> Vector3:
	var a := TAU * float(index) / float(slots)
	return centre + Vector3(sin(a), 0.0, -cos(a)) * radius
