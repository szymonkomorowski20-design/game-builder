class_name GuardBrain
extends RefCounted
## One guard's alert states (recipe 69, genre doc §5):
## - PATROL → SUSPICIOUS: something seen or heard; the guard stops and stares for `turn_time`;
## - SUSPICIOUS → INVESTIGATE: the guard that claims the stimulus on the board walks there, looks around, goes back (a
##   cautious search: one guard, so the player can lure guards away one at a time);
## - → ALERT: detected. The guard runs at the player. After `call_delay` its call for support reaches the board and
##   nearby guards come; silence it before that and nobody hears. A lost player is still "known" for `memory` seconds
##   (the guard runs to where the player really is), then only the last seen place counts;
## - → SEARCH: at the last seen place, over the board's search points, for `search_time` at most;
## - → RETURN to the post, with raised caution for `caution_time` (the guard notices faster, recipe 68).
## Pure logic: the host walks the guard to `goal` (running or not), faces `look_at`, feeds `tick()` with what the
## senses report, and resets the awareness meter when `wants_reset` is set.

enum State { PATROL, SUSPICIOUS, INVESTIGATE, ALERT, SEARCH, RETURN }

## Stimulus priorities (after Mark of the Ninja's table, genre doc §5): a higher one replaces a lower; on equal
## priority the newest wins.
const PRIORITY := {&"damaged": 1, &"missing": 2, &"noise": 4, &"body": 4, &"silhouette": 4, &"distraction": 10,
		&"terror": 20}

var board: AlertBoard
var post := Vector3.ZERO
var state: int = State.PATROL
var goal := Vector3.ZERO
var running := false
var look_at := Vector3.ZERO
var caution_until := -INF
var wants_reset := false
var alarms_raised := 0

var turn_time := 1.0
var look_around_time := 2.0
var memory := 2.5
var call_delay := 1.5
var search_time := 30.0
var search_radius := 15.0
var caution_time := 60.0
var arrive_distance := 0.8
## Where a search looks: the level's hiding places and corners; `hidden_from.call(from, point) -> bool`.
var search_candidates: Array[Vector3] = []
var hidden_from: Callable = Callable()

var _entered := 0.0
var _stimulus := {}
var _last_seen := Vector3.ZERO
var _lost_at := -INF
var _called := false
var _arrived_at := -INF
var _alarm_seen := 0
var _search_goal: Variant = null


func _init(p_board: AlertBoard = null, p_post: Vector3 = Vector3.ZERO) -> void:
	board = p_board if p_board != null else AlertBoard.new()
	post = p_post
	goal = p_post
	_alarm_seen = board.alarm_id


## Something the guard heard or found: `kind` (a PRIORITY key), `key` (one investigator per key), `pos`.
func notice(kind: StringName, key: String, pos: Vector3, now: float) -> void:
	var p := int(PRIORITY.get(kind, 4))
	if not _stimulus.is_empty() and p < int(_stimulus.priority):
		return
	_stimulus = {kind = kind, key = key, pos = pos, priority = p, at = now}


## The stimulus being handled ({kind, key, pos, priority, at}), or {}.
func stimulus() -> Dictionary:
	return _stimulus


## &"alert" while hunting, &"caution" for a while after a search, else &"" — for the senses (recipe 68).
func guard_state(now: float) -> StringName:
	if state == State.ALERT or state == State.SEARCH:
		return &"alert"
	return &"caution" if now < caution_until else &""


## One step. `sense`: level (an AwarenessMeter level), seen, seen_at, and true_pos (the player's real position, used
## only within `memory` after losing sight). `at`: the guard's own position.
func tick(now: float, sense: Dictionary, at: Vector3) -> void:
	var level := int(sense.get("level", 0))
	var seen: bool = sense.get("seen", false) == true
	var seen_at: Vector3 = sense.get("seen_at", Vector3.ZERO)
	match state:
		State.PATROL, State.RETURN:
			if level == AwarenessMeter.DETECTED and seen:
				_alert(now, seen_at)
			elif level >= AwarenessMeter.SUSPICIOUS and seen:
				notice(&"silhouette", "sight", seen_at, now)
				look_at = seen_at
				_enter(State.SUSPICIOUS, now)
			elif not _stimulus.is_empty():
				look_at = _stimulus.pos
				_enter(State.SUSPICIOUS, now)
			elif not _answer_alarm(now, at) and state == State.RETURN:
				goal = post
				running = false
				if at.distance_to(post) <= arrive_distance:
					_enter(State.PATROL, now)
		State.SUSPICIOUS:
			running = false
			goal = at
			look_at = seen_at if seen else _stimulus.get("pos", look_at)
			if level == AwarenessMeter.DETECTED and seen:
				_alert(now, seen_at)
			elif now - _entered >= turn_time:
				if not _stimulus.is_empty() and board.claim_investigation(_stimulus.key, self):
					goal = _stimulus.pos
					_enter(State.INVESTIGATE, now)
				else:
					_stimulus = {}
					_enter(State.RETURN, now)
		State.INVESTIGATE:
			_investigate(now, level, seen, seen_at, at)
		State.ALERT:
			if not _called and now - _entered >= call_delay:
				_called = true
				board.raise_alarm(_last_seen, now)
				_alarm_seen = board.alarm_id
				alarms_raised += 1
			if seen:
				_chase(now, seen_at)
			elif now - _lost_at <= memory:
				goal = sense.get("true_pos", _last_seen)
			else:
				goal = _last_seen
				if at.distance_to(goal) <= arrive_distance:
					_start_search(now, _last_seen, at)
		State.SEARCH:
			running = true
			if seen and level >= AwarenessMeter.SUSPICIOUS:
				_alert(now, seen_at)
			elif now - _entered >= search_time:
				_calm_down(now)
			else:
				if _search_goal == null:
					_search_goal = board.next_point(self)
					if _search_goal == null:
						_calm_down(now)
						return
				goal = _search_goal
				if at.distance_to(goal) <= arrive_distance:
					board.tick_off(goal)
					_search_goal = null


func _investigate(now: float, level: int, seen: bool, seen_at: Vector3, at: Vector3) -> void:
	running = false
	if level == AwarenessMeter.DETECTED and seen:
		_alert(now, seen_at)
		return
	goal = _stimulus.pos
	if at.distance_to(goal) > arrive_distance:
		return
	if _arrived_at < _entered:
		_arrived_at = now
		if _stimulus.kind == &"body":
			board.raise_alarm(goal, now)
			_alarm_seen = board.alarm_id
			alarms_raised += 1
			board.release_investigation(_stimulus.key, self)
			_start_search(now, goal, at)
			return
	look_at = goal
	if now - _arrived_at >= look_around_time:
		board.release_investigation(_stimulus.key, self)
		_stimulus = {}
		_enter(State.RETURN, now)


func _alert(now: float, seen_at: Vector3) -> void:
	if not _stimulus.is_empty():
		board.release_investigation(_stimulus.key, self)
		_stimulus = {}
	_enter(State.ALERT, now)
	_called = false
	_chase(now, seen_at)


func _chase(now: float, seen_at: Vector3) -> void:
	goal = seen_at
	running = true
	_last_seen = seen_at
	_lost_at = now
	board.report_seen(seen_at, now)


## A fresh alarm within the board's radius: run to it (the guard doesn't know where the player is now).
func _answer_alarm(now: float, at: Vector3) -> bool:
	if board.alarm_id == _alarm_seen:
		return false
	_alarm_seen = board.alarm_id
	if at.distance_to(board.alarm_at) > board.alarm_radius:
		return false
	_enter(State.ALERT, now)
	_called = true
	_last_seen = board.alarm_at
	_lost_at = -INF
	goal = board.alarm_at
	running = true
	return true


func _start_search(now: float, estimate: Vector3, at: Vector3) -> void:
	if not board.join_search(self):
		_calm_down(now)
		return
	if board.plan_estimate == Vector3.INF or board.plan_estimate.distance_to(estimate) > 3.0:
		board.plan_search(estimate, search_candidates, search_radius, hidden_from)
	_search_goal = null
	goal = at
	_enter(State.SEARCH, now)


func _calm_down(now: float) -> void:
	board.leave_search(self)
	_search_goal = null
	_stimulus = {}
	caution_until = now + caution_time
	wants_reset = true
	running = false
	goal = post
	_enter(State.RETURN, now)


func _enter(s: int, now: float) -> void:
	state = s
	_entered = now
