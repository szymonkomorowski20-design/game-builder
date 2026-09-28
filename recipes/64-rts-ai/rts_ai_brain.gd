class_name RtsAiBrain
extends RefCounted
## A skirmish opponent (recipe 64) built the way commercial RTS AIs are (see the genre doc): a priority list checked a
## few times a second, attack waves, and difficulty as reaction time and income — honestly named, not hidden.
## Every `think_interval` seconds it:
##   1. builds a farm when free supply runs low and none is on its way;
##   2. keeps making workers up to `worker_target`;
##   3. walks the build order (a list of {kind, count}): the first entry it has fewer of than `count` is the goal —
##      it is ordered when affordable, otherwise the AI **saves up** for it (it doesn't skip ahead to cheaper things);
##      an entry locked by the tech tree is skipped (list prerequisites before what needs them);
##   4. sends the army as a wave (attack-move to the enemy's base) once it has `wave_size` units; each wave is bigger;
##   5. pulls the wave back home when the fight goes badly (its power below `retreat_ratio` × the enemy's there).
## The game gives it a `world` object with these methods (the test has a fake one):
##   count(kind) -> int                 own ones, including those being made
##   pending(kind) -> int               those being made
##   supply_free() -> int
##   can_afford(kind) -> bool
##   available(kind) -> bool            the tech tree allows it
##   order(kind) -> bool                start making / building it
##   army() -> Array                    own military units
##   power(units: Array) -> float       their fighting value (e.g. the sum of cost)
##   enemy_power_near(at: Vector3) -> float
##   army_centre() -> Vector3
##   attack(units: Array, at: Vector3); retreat(units: Array, to: Vector3)
##   enemy_base() -> Vector3; home() -> Vector3

signal decided(what: String)

var world: Object
var build_order: Array[Dictionary] = []      ## [{kind, count}]
var worker_kind: StringName = &"worker"
var worker_target := 14
var farm_kind: StringName = &"farm"
var supply_margin := 4
var think_interval := 1.0
var wave_size := 6
var wave_growth := 2
var retreat_ratio := 0.6
var attacking := false
var waves_sent := 0

var _t := 0.0


## Difficulty presets: how fast it reacts, how big its first wave is, and the income multiplier the game applies to its
## workers' deliveries (a cheat, as in the genre — say so on the difficulty screen).
static func preset(level: int) -> Dictionary:
	match level:
		0:
			return {"think_interval": 2.0, "wave_size": 5, "wave_growth": 1, "income_multiplier": 0.8}
		2:
			return {"think_interval": 0.5, "wave_size": 8, "wave_growth": 3, "income_multiplier": 1.3}
	return {"think_interval": 1.0, "wave_size": 6, "wave_growth": 2, "income_multiplier": 1.0}


func apply_preset(level: int) -> void:
	var p := preset(level)
	think_interval = p.think_interval
	wave_size = p.wave_size
	wave_growth = p.wave_growth


func tick(delta: float) -> void:
	_t += delta
	if _t < think_interval:
		return
	_t = 0.0
	think()


func think() -> void:
	# 1. Supply first: a blocked AI is a dead AI.
	if world.supply_free() < supply_margin and world.pending(farm_kind) == 0 and world.available(farm_kind):
		if world.can_afford(farm_kind) and world.order(farm_kind):
			decided.emit("farm")
		return                                  # save for the farm before anything else
	# 2. Workers.
	if world.count(worker_kind) < worker_target and world.pending(worker_kind) == 0 and world.can_afford(worker_kind):
		if world.order(worker_kind):
			decided.emit("worker")
	# 3. The build order.
	for step in build_order:
		var kind: StringName = step.kind
		if world.count(kind) >= int(step.count):
			continue
		if not world.available(kind):
			continue                            # locked by tech: its prerequisite should come earlier in the list
		if world.can_afford(kind) and world.order(kind):
			decided.emit("build " + String(kind))
		break                                   # the top goal waits for money; nothing cheaper jumps the queue
	# 4–5. The army.
	var army: Array = world.army()
	if army.is_empty():
		attacking = false
		return
	if attacking:
		var here: Vector3 = world.army_centre()
		if world.power(army) < world.enemy_power_near(here) * retreat_ratio:
			world.retreat(army, world.home())
			attacking = false
			decided.emit("retreat")
	elif army.size() >= wave_size:
		world.attack(army, world.enemy_base())
		attacking = true
		waves_sent += 1
		wave_size += wave_growth
		decided.emit("wave %d" % waves_sent)
