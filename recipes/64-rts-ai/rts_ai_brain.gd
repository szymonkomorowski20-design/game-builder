class_name RtsAiBrain
extends RefCounted
## A skirmish opponent (recipe 64) built the way commercial RTS AIs are (see the genre doc): a priority list checked a
## few times a second, attack waves, and difficulty as reaction time and income — honestly named, not hidden.
## Every `think_interval` seconds it:
##   1. builds a farm when free supply runs low and none is on its way (not at the supply ceiling);
##   2. keeps making workers up to `worker_target`;
##   3. walks the build order (a list of {kind, count}): the first entry it has fewer of than `count` is the goal —
##      it is ordered when affordable, otherwise the AI **saves up** for it (it doesn't skip ahead to cheaper things);
##      an entry locked by the tech tree waits when what unlocks it is on its way (`unlocking`), and is skipped when
##      nothing is (list prerequisites before what needs them);
##   4. sends the army as a wave (attack-move to the enemy's base) once it has `wave_size` units; each wave is bigger,
##      up to `max_wave_size` (a wave larger than the supply allows would never leave); an army that hasn't grown
##      for `stall_after` s goes anyway (when the gold runs out, a wave it can no longer reach would stall the game);
##      no wave before `first_wave_not_before` s; with `cap_first_wave`, the first wave is `wave_size` units and the rest
##      stay home (after a long wait the whole army would be one crushing first wave);
##   4b. between waves, sends the army at enemies that come near its buildings (`threat()`);
##   5. keeps the wave pushing (idle units of a wave are sent on at the enemy's base — the base moves as buildings
##      fall), and pulls it back home when the fight goes badly (its power below `retreat_ratio` × the enemy's there).
## The game gives it a `world` object with these methods (the test has a fake one):
##   count(kind) -> int                 own ones, including those being made
##   pending(kind) -> int               those being made
##   supply_free() -> int
##   supply_maxed() -> bool             (optional) at the supply ceiling: farms would add nothing
##   can_afford(kind) -> bool
##   available(kind) -> bool            the tech tree allows it
##   unlocking(kind) -> bool            (optional) what it needs is being built or researched now
##   threat() -> Vector3                (optional) the nearest enemy near its buildings, or Vector3.INF
##   order(kind) -> bool                start making / building it
##   army() -> Array                    own military units
##   power(units: Array) -> float       their fighting value (e.g. the sum of cost)
##   enemy_power_near(at: Vector3) -> float
##   centre_of(units: Array) -> Vector3   (optional: where a wave is; else army_centre())
##   army_centre() -> Vector3
##   attack(units: Array, at: Vector3)  called every think while a wave is out: order the idle ones only
##   retreat(units: Array, to: Vector3)
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
var max_wave_size := 20
var stall_after := 60.0                 ## s at home without growing (after the first wave): the next wave goes with what it has
var first_wave_not_before := 0.0        ## s from the start before the first wave may leave (a rush in 2–3 minutes is a pitfall)
var cap_first_wave := false             ## the first wave is at most `wave_size` units; the rest stay home
var _last_army := 0
var _since_growth := 0.0
var _clock := 0.0
var _first: Array = []                  ## the first wave's units while it is out (cap_first_wave)
var retreat_ratio := 0.6
var attacking := false
var waves_sent := 0

var _t := 0.0


## Difficulty presets: how fast it reacts, how big its first wave is, the income multiplier the game applies to its
## workers' deliveries (a cheat, as in the genre — say so on the difficulty screen), how many production buildings it
## runs at most (`production`) and the food ceiling of its army (`max_supply`, under the rules' own). Without the last two
## a computer bound by its production and the game's food ceiling turns more income into a bigger bank, not a bigger
## army: measured in Kamienna Marchia, phase 5 — easy and normal fielded the same army at 6 minutes, and once farms kept
## up, normal and hard both sat at the ceiling.
static func preset(level: int) -> Dictionary:
	match level:
		0:
			return {"think_interval": 2.0, "wave_size": 5, "wave_growth": 1, "income_multiplier": 0.8, "production": 2, "max_supply": 70}
		2:
			return {"think_interval": 0.5, "wave_size": 8, "wave_growth": 3, "income_multiplier": 1.3, "production": 4, "max_supply": 100}
	return {"think_interval": 1.0, "wave_size": 6, "wave_growth": 2, "income_multiplier": 1.0, "production": 3, "max_supply": 85}


func apply_preset(level: int) -> void:
	var p := preset(level)
	think_interval = p.think_interval
	wave_size = p.wave_size
	wave_growth = p.wave_growth


func tick(delta: float) -> void:
	_clock += delta
	_t += delta
	if _t < think_interval:
		return
	_t = 0.0
	think()


func think() -> void:
	# 1. Supply first: a blocked AI is a dead AI.
	var maxed: bool = world.has_method(&"supply_maxed") and world.supply_maxed()
	if not maxed and world.supply_free() < supply_margin and world.pending(farm_kind) == 0 and world.available(farm_kind):
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
			if world.has_method(&"unlocking") and world.unlocking(kind):
				break                           # its prerequisite is on its way: wait, don't jump ahead
			continue                            # nothing unlocks it yet: its prerequisite should come earlier in the list
		if world.can_afford(kind) and world.order(kind):
			decided.emit("build " + String(kind))
		break                                   # the top goal waits for money; nothing cheaper jumps the queue
	# 4–5. The army.
	var army: Array = world.army()
	if army.size() > _last_army or attacking:
		_since_growth = 0.0                     # counts only while the army is home and not growing
	else:
		_since_growth += think_interval
	_last_army = army.size()
	if army.is_empty():
		attacking = false
		return
	if attacking:
		var out: Array = army
		if not _first.is_empty():
			out = _first.filter(func(u: Variant) -> bool: return army.has(u))
			if out.is_empty():
				_first = []
				attacking = false                   # the first wave is gone; the next one is built as usual
				return
		var here: Vector3 = world.centre_of(out) if world.has_method(&"centre_of") else world.army_centre()     # where the wave is, not the whole army
		if world.power(out) < world.enemy_power_near(here) * retreat_ratio:
			world.retreat(out, world.home())
			attacking = false
			_first = []
			_since_growth = 0.0                   # a beaten army rebuilds before it goes again
			decided.emit("retreat")
		else:
			world.attack(out, world.enemy_base())      # keep pushing: the world re-orders idle units only
		if not _first.is_empty() and world.has_method(&"threat") and world.threat() != Vector3.INF:
			var home := army.filter(func(u: Variant) -> bool: return not _first.has(u))
			if not home.is_empty():
				world.attack(home, world.threat())      # the units kept home defend it while the first wave is out
				decided.emit("defend")
	elif world.has_method(&"threat") and world.threat() != Vector3.INF:
		world.attack(army, world.threat())           # defend: the idle army goes at whoever came near the base
		decided.emit("defend")
	elif _clock >= first_wave_not_before and (army.size() >= mini(wave_size, max_wave_size) or (waves_sent > 0 and _since_growth >= stall_after)):
		var wave: Array = army
		if cap_first_wave and waves_sent == 0:
			wave = army.slice(0, mini(wave_size, max_wave_size))
			_first = wave.duplicate()
		world.attack(wave, world.enemy_base())
		attacking = true
		waves_sent += 1
		wave_size += wave_growth
		decided.emit("wave %d" % waves_sent)
