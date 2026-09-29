class_name WantedSearch
extends RefCounted
## Losing the pursuers (recipe 72, genre doc §8), after GTA IV and Assassin's Creed II:
## - SEEN while a guard sees the player (the host calls `seen()` every frame it does);
## - LOST once nobody has for `lost_after` s: a search circle stays at the last seen place, its radius set by the
##   notoriety level;
## - ESCAPED after staying out of the circle for `escape_time` s, or hiding (hay, a bench, a crowd) for `hide_time` s;
##   seen again, the chase is back on and the timers start over.
## Detection changes the situation instead of ending the mission (genre doc §9): the escape is the game.

enum State { CALM, SEEN, LOST, ESCAPED }

var state: int = State.CALM
var centre := Vector3.ZERO
var radius := 20.0
var radii: Array[float] = [15.0, 20.0, 30.0, 40.0]
var lost_after := 0.5
var escape_time := 4.0
var hide_time := 3.0

var _seen_at := -INF
var _out_since := -INF
var _hidden_since := -INF


## A guard sees the player at `at` (every frame it does). `level`: the notoriety level, for the circle's size.
func seen(at: Vector3, now: float, level: int = 0) -> void:
	state = State.SEEN
	centre = at
	radius = radii[clampi(level, 0, radii.size() - 1)]
	_seen_at = now
	_out_since = -INF
	_hidden_since = -INF


func tick(now: float, player: Vector3, hidden: bool) -> int:
	match state:
		State.SEEN:
			if now - _seen_at >= lost_after:
				state = State.LOST
		State.LOST:
			var outside := Vector2(player.x - centre.x, player.z - centre.z).length() > radius
			if outside:
				if _out_since == -INF:
					_out_since = now
			else:
				_out_since = -INF
			if hidden:
				if _hidden_since == -INF:
					_hidden_since = now
			else:
				_hidden_since = -INF
			if (outside and now - _out_since >= escape_time) or (hidden and now - _hidden_since >= hide_time):
				state = State.ESCAPED
	return state


func is_chased() -> bool:
	return state == State.SEEN or state == State.LOST


func reset() -> void:
	state = State.CALM
	_seen_at = -INF
	_out_since = -INF
	_hidden_since = -INF
