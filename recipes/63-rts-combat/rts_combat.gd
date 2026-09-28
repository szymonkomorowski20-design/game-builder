class_name RtsCombat
extends RefCounted
## RTS combat rules (recipe 63), as data and pure functions.
## - **Damage:** base + bonus against the target's tags (e.g. +10 vs "armored"), times the attack-type × armour-type
##   multiplier from `table`, minus the target's armour, never below `min_damage`. Bonus comes before armour, and
##   armour is a flat subtraction with a floor (the StarCraft II model); the type table is the Warcraft III idea of
##   counters. Both are optional: an empty table multiplies by 1.
## - **Targets:** `pick_target` chooses what an idle or attack-moving unit fights: something attacking it first, then
##   the nearest unit, buildings last, only inside `acquire` range and only what its team can see. It keeps its current
##   target while that is still valid, so it doesn't twitch between two enemies.
## - **Leash:** a unit chasing on its own (not ordered) gives up beyond `leash` from where it started.

var table := {}                 ## attack type → {armour type → multiplier}
var min_damage := 0.5


## One hit. attack: {damage, type, bonus: {tag → extra}}; target: {armour, armour_type, tags: [..]}.
func damage(attack: Dictionary, target: Dictionary) -> float:
	var d := float(attack.get("damage", 0.0))
	var tags: Array = target.get("tags", [])
	var bonus: Dictionary = attack.get("bonus", {})
	for tag in bonus:
		if tags.has(tag):
			d += float(bonus[tag])
	var row: Dictionary = table.get(attack.get("type", &""), {})
	d *= float(row.get(target.get("armour_type", &""), 1.0))
	d -= float(target.get("armour", 0.0))
	return maxf(d, min_damage)


## Hits needed to kill `hp` (for the balance sheet and the counter contracts).
func hits_to_kill(attack: Dictionary, target: Dictionary, hp: float) -> int:
	return ceili(hp / damage(attack, target))


## The best target for a unit at `from` with `acquire` range. candidates: [{node, at: Vector3, is_building: bool,
## attacking_me: bool, visible: bool}]. `current`: the node it fights now (kept if still a candidate in range).
static func pick_target(from: Vector3, acquire: float, candidates: Array, current: Object = null) -> Object:
	var best: Object = null
	var best_score := INF
	for c in candidates:
		if not bool(c.get("visible", true)):
			continue
		var node: Object = c.node
		if node == null or not is_instance_valid(node):
			continue
		var d := from.distance_to(c.at)
		if d > acquire:
			continue
		if node == current:
			return current                          # stick with it while it is valid and in range
		var score := d
		if bool(c.get("is_building", false)):
			score += 1000.0                         # units first
		if bool(c.get("attacking_me", false)):
			score -= 500.0                          # whoever hits me, before the nearest bystander
		if score < best_score:
			best_score = score
			best = node
	return best


## A unit chasing on its own gives up when it is `leash` metres from where the chase began.
static func should_give_up(chase_start: Vector3, at: Vector3, leash: float) -> bool:
	return chase_start.distance_to(at) > leash
