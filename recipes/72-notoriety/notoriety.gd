class_name Notoriety
extends RefCounted
## How well known the player is in the district (recipe 72, genre doc §8): a value 0–100 read as levels 0–3.
## - Acts add to it when someone sees them. A guard's sighting counts at once; a civilian first has to get the word
##   to the guards (`report_time`), and a witness stopped in time reports nothing (the witnesses of Watch Dogs).
## - Actions take it down: tearing down a wanted poster (−25), bribing a herald (halves it). There is no passive decay
##   by default, as in the Assassin's Creed games that have posters; `decay_per_s` makes a gentler game.
## - Each level has named effects the game applies: how much faster guards notice (recipe 68), attack on sight, guards
##   on the roofs, a hunter.

const ACTS := {&"kill": 30.0, &"fight": 15.0, &"trespass": 10.0, &"theft": 8.0, &"shove": 3.0, &"climb_seen": 2.0}

var value := 0.0
var thresholds: Array[float] = [25.0, 55.0, 85.0]
var decay_per_s := 0.0
var report_time := 6.0
var poster := 25.0
var effects: Array[Dictionary] = [
	{notice = 1.0, attack_on_sight = false, roof_guards = false, hunter = false},
	{notice = 1.3, attack_on_sight = false, roof_guards = false, hunter = false},
	{notice = 1.7, attack_on_sight = false, roof_guards = true, hunter = false},
	{notice = 2.5, attack_on_sight = true, roof_guards = true, hunter = true},
]

var _reports := {}
var _next_id := 1


func level() -> int:
	var l := 0
	for t in thresholds:
		if value >= t:
			l += 1
	return l


func effect() -> Dictionary:
	return effects[level()]


## An act of `act` (an ACTS key) seen by a guard (counts now) or a civilian (a pending report: its id, to stop it).
## Returns 0 when it counted at once.
func witnessed(act: StringName, by_guard: bool, now: float) -> int:
	var amount := float(ACTS.get(act, 5.0))
	if by_guard:
		_add(amount)
		return 0
	var id := _next_id
	_next_id += 1
	_reports[id] = {amount = amount, due = now + report_time}
	return id


## The witness was stopped before reporting. True when there was a report to stop.
func stop_witness(id: int) -> bool:
	return _reports.erase(id)


func pending_reports() -> int:
	return _reports.size()


func tick(now: float, delta: float) -> void:
	for id: int in _reports.keys():
		if now >= float(_reports[id].due):
			_add(float(_reports[id].amount))
			_reports.erase(id)
	if decay_per_s > 0.0:
		value = maxf(value - decay_per_s * delta, 0.0)


func tear_poster() -> void:
	value = maxf(value - poster, 0.0)


func bribe_herald() -> void:
	value *= 0.5


func _add(amount: float) -> void:
	value = clampf(value + amount, 0.0, 100.0)
