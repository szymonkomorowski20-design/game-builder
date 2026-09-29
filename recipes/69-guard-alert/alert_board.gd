class_name AlertBoard
extends RefCounted
## What the guards of one area know together, and who does what (recipe 69, genre doc §5):
## - the player's last known position and time, written only by a guard who sees the player (honest knowledge);
## - an alarm (a guard's call for support, a body) that nearby guards answer;
## - one investigator per stimulus: a distraction pulls one guard, so the player can split a group;
## - at most `max_searchers` searching at once;
## - search points around an estimate, hidden places first, each taken by one guard and ticked off once checked.

var max_searchers := 3
var alarm_radius := 25.0
var last_known := Vector3.ZERO
var last_known_at := -INF
var alarm_at := Vector3.ZERO
var alarm_time := -INF
var alarm_id := 0
var plan_estimate := Vector3.INF

var _investigators := {}
var _searchers := {}
var _points: Array[Vector3] = []
var _checked: Array[bool] = []
var _claimed := {}


func report_seen(pos: Vector3, now: float) -> void:
	last_known = pos
	last_known_at = now


func raise_alarm(pos: Vector3, now: float) -> void:
	alarm_at = pos
	alarm_time = now
	alarm_id += 1


## True for the first guard to claim `key` (and for that same guard again), false for everyone else.
func claim_investigation(key: String, guard: Object) -> bool:
	var id := guard.get_instance_id()
	if _investigators.has(key) and _investigators[key] != id:
		return false
	_investigators[key] = id
	return true


func release_investigation(key: String, guard: Object) -> void:
	if _investigators.get(key, 0) == guard.get_instance_id():
		_investigators.erase(key)


func join_search(guard: Object) -> bool:
	var id := guard.get_instance_id()
	if _searchers.has(id):
		return true
	if _searchers.size() >= max_searchers:
		return false
	_searchers[id] = true
	return true


func leave_search(guard: Object) -> void:
	var id := guard.get_instance_id()
	_searchers.erase(id)
	for i: int in _claimed.keys():
		if _claimed[i] == id:
			_claimed.erase(i)


func searchers() -> int:
	return _searchers.size()


## Search points from `candidates` within `radius` of `estimate`: the ones hidden from the estimate first (where
## someone who just broke line of sight would be; `hidden_from.call(estimate, point) -> bool`), then by distance.
func plan_search(estimate: Vector3, candidates: Array[Vector3], radius: float,
		hidden_from: Callable = Callable()) -> void:
	var scored: Array = []
	for c in candidates:
		var d := c.distance_to(estimate)
		if d > radius:
			continue
		var hidden: bool = hidden_from.is_valid() and hidden_from.call(estimate, c) == true
		scored.append([(0.0 if hidden else 1000.0) + d, c])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	_points.clear()
	_checked.clear()
	_claimed.clear()
	for s: Array in scored:
		_points.append(s[1])
		_checked.append(false)
	plan_estimate = estimate


## The first unchecked point nobody else holds (in plan order), taken by `guard`; null when none is left.
func next_point(guard: Object) -> Variant:
	var id := guard.get_instance_id()
	for i in _points.size():
		if _checked[i]:
			continue
		if _claimed.has(i) and _claimed[i] != id:
			continue
		_claimed[i] = id
		return _points[i]
	return null


## Marks the point at `pos` (within 0.5 m) as checked.
func tick_off(pos: Vector3) -> void:
	for i in _points.size():
		if not _checked[i] and _points[i].distance_to(pos) < 0.5:
			_checked[i] = true
			_claimed.erase(i)
			return


func points_left() -> int:
	return _checked.count(false)
