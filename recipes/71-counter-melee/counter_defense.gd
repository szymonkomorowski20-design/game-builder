class_name CounterDefense
extends RefCounted
## The player's answer to an enemy's hit (recipe 71, genre doc §11). Counter is pressed within `window` before the hit
## (within `perfect` it stuns); block is held; a dodge press within `dodge_window` avoids the hit. Mashing doesn't
## work: each earlier press within `spam_window` shrinks the window (as in Sekiro). A press answers one hit. The host
## cancels the player's own attack on a counter press: Arkham Origins stopped that, and players were hit without
## knowing why.

enum Result { HIT, BLOCKED, COUNTERED, PERFECT, DODGED, GUARD_BROKEN }

var window := 0.35
var perfect := 0.1
var dodge_window := 0.4
var spam_window := 0.5
var spam_shrink := 0.5
var blocking := false

var _counters: Array[float] = []
var _dodges: Array[float] = []


func press_counter(now: float) -> void:
	_counters.append(now)


func press_dodge(now: float) -> void:
	_dodges.append(now)


## The window a counter pressed at `at` gets: shrunk once for every earlier press within `spam_window`.
func effective_window(at: float) -> float:
	var earlier := 0
	for p in _counters:
		if p < at and at - p <= spam_window:
			earlier += 1
	return window * pow(spam_shrink, earlier)


## How a hit of `kind` landing at `hit_time` ends. The press that answered it is used up.
func resolve(kind: int, hit_time: float) -> int:
	var dodge := _answer(_dodges, hit_time, func(_p: float) -> float: return dodge_window)
	if kind == EnemyStrike.Kind.UNBLOCKABLE:
		if dodge >= 0:
			_dodges.remove_at(dodge)
			return Result.DODGED
		var tried := _answer(_counters, hit_time, effective_window)
		if tried >= 0:
			_counters.remove_at(tried)
			return Result.GUARD_BROKEN
		return Result.GUARD_BROKEN if blocking else Result.HIT
	var counter := _answer(_counters, hit_time, effective_window)
	if counter >= 0:
		var lead := hit_time - _counters[counter]
		_counters.remove_at(counter)
		return Result.PERFECT if lead <= perfect else Result.COUNTERED
	if dodge >= 0:
		_dodges.remove_at(dodge)
		return Result.DODGED
	return Result.BLOCKED if blocking else Result.HIT


## Forgets presses older than any window (call now and then).
func forget_before(t: float) -> void:
	for list: Array[float] in [_counters, _dodges]:
		for i in range(list.size() - 1, -1, -1):
			if list[i] < t:
				list.remove_at(i)


## The latest press at or before `hit_time` whose window covers the hit, or -1.
static func _answer(presses: Array[float], hit_time: float, window_of: Callable) -> int:
	var best := -1
	for i in presses.size():
		var p := presses[i]
		if p <= hit_time and hit_time - p <= float(window_of.call(p)):
			if best < 0 or p > presses[best]:
				best = i
	return best
