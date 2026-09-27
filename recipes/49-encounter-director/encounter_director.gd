class_name EncounterDirector
extends RefCounted
## Plans and runs a combat room. plan(depth, seed) builds waves out of a threat budget that grows with depth: each
## wave first takes one of each affordable enemy type (variety), then fills the rest at random until nothing fits.
## Running it: start() spawns wave 0; the host reports each death with enemy_died(); when a wave is gone the next
## one starts after `wave_delay`; `cleared` fires once when the last wave is dead (open the doors, give the reward).

signal wave_started(index: int, enemy_ids: Array)
signal cleared

var kinds: Array[EnemyKind] = []
var base_budget := 4.0
var budget_per_depth := 1.5
var depth_per_extra_wave := 3      ## depth 0–2: one wave, 3–5: two, …
var max_waves := 3
var variety := 3                   ## distinct types placed first in each wave
var wave_delay := 1.0

var current_plan: Array = []
var wave_index := -1
var alive := 0
var _waiting := -1.0
var _cleared := false


func kind(id: StringName) -> EnemyKind:
	for k in kinds:
		if k.id == id:
			return k
	return null


func wave_budget(depth: int) -> int:
	return floori(base_budget + budget_per_depth * depth)


func wave_count(depth: int) -> int:
	return mini(1 + depth / depth_per_extra_wave, max_waves)


func plan(depth: int, seed: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var open := kinds.filter(func(k: EnemyKind) -> bool: return k.min_depth <= depth)
	var waves := []
	for w in wave_count(depth):
		var remaining := wave_budget(depth)
		var wave: Array[StringName] = []
		var first := open.duplicate()
		_shuffle(first, rng)
		for k: EnemyKind in first.slice(0, variety):
			if k.cost <= remaining:
				wave.append(k.id)
				remaining -= k.cost
		while true:
			var fits := open.filter(func(k: EnemyKind) -> bool: return k.cost <= remaining)
			if fits.is_empty():
				break
			var pick: EnemyKind = fits[rng.randi_range(0, fits.size() - 1)]
			wave.append(pick.id)
			remaining -= pick.cost
		waves.append(wave)
	return waves


func start(depth: int, seed: int) -> void:
	current_plan = plan(depth, seed)
	wave_index = -1
	_cleared = false
	_next_wave()


func enemy_died() -> void:
	if _cleared or alive <= 0:
		return
	alive -= 1
	if alive > 0:
		return
	if wave_index >= current_plan.size() - 1:
		_cleared = true
		cleared.emit()
	else:
		_waiting = wave_delay


func tick(delta: float) -> void:
	if _waiting < 0.0:
		return
	_waiting -= delta
	if _waiting <= 0.0:
		_waiting = -1.0
		_next_wave()


func is_cleared() -> bool:
	return _cleared


func _next_wave() -> void:
	wave_index += 1
	var ids: Array = current_plan[wave_index]
	alive = ids.size()
	wave_started.emit(wave_index, ids)


func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp
