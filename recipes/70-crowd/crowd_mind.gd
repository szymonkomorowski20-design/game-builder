class_name CrowdMind
extends RefCounted
## One civilian's mood and reaction (recipe 70, genre doc §7):
## - moods only get worse from a stimulus: AMBIENT < ALERT < SCARED < PANIC (Hitman: an agent changes state only when
##   the imposed mood is worse than its own);
## - a reaction runs in four phases (Watch Dogs 2): REACT (a short look), REPOSITION (move away to a watching or a
##   fleeing distance), MAIN (watch or keep fleeing), CALM (settle down), then back to AMBIENT — never from panic
##   straight to calm walking;
## - after calming down, small alarms are ignored for `cooldown` seconds, so nobody swings between extremes.
## Pure logic: the host moves the civilian toward `goal()` at `speed_scale()` times its walking speed.

enum Mood { AMBIENT, ALERT, SCARED, PANIC }
enum Phase { NONE, REACT, REPOSITION, MAIN, CALM }

var mood: int = Mood.AMBIENT
var phase: int = Phase.NONE
var source := Vector3.ZERO
var calm_until := -INF

var react_time := 0.6
var reposition_max := 4.0          ## s at most to get to the distance
var main_time := {Mood.ALERT: 4.0, Mood.SCARED: 6.0, Mood.PANIC: 10.0}
var calm_time := 3.0
var cooldown := 8.0
var watch_distance := 6.0          ## an alerted civilian keeps this far and watches
var flee_distance := 18.0          ## a scared or panicking one runs this far
var speeds := {Mood.AMBIENT: 1.0, Mood.ALERT: 0.9, Mood.SCARED: 1.8, Mood.PANIC: 2.6}

var _phase_at := 0.0


## A stimulus of mood `m` at `at`. Only a worse mood takes effect; after calming down, ALERT is ignored for a while.
## Returns true when it changed the civilian.
func stimulate(m: int, at: Vector3, now: float) -> bool:
	if m <= mood:
		return false
	if mood == Mood.AMBIENT and m == Mood.ALERT and now < calm_until:
		return false
	mood = m
	source = at
	_set_phase(Phase.REACT, now)
	return true


func tick(now: float, pos: Vector3) -> void:
	var in_phase := now - _phase_at
	match phase:
		Phase.REACT:
			if in_phase >= react_time:
				_set_phase(Phase.REPOSITION, now)
		Phase.REPOSITION:
			if pos.distance_to(source) >= _distance() - 0.5 or in_phase >= reposition_max:
				_set_phase(Phase.MAIN, now)
		Phase.MAIN:
			if in_phase >= float(main_time.get(mood, 4.0)):
				_set_phase(Phase.CALM, now)
		Phase.CALM:
			if in_phase >= calm_time:
				mood = Mood.AMBIENT
				calm_until = now + cooldown
				_set_phase(Phase.NONE, now)


## Where to go now: away from the source to the phase's distance, or null (walk the lanes; stand while reacting).
func goal(pos: Vector3) -> Variant:
	if phase == Phase.REPOSITION or (phase == Phase.MAIN and mood >= Mood.SCARED):
		var away := pos - source
		away.y = 0.0
		if away.length_squared() < 1e-6:
			away = Vector3.FORWARD
		return source + away.normalized() * _distance()
	return null


func speed_scale() -> float:
	if phase == Phase.REACT or (phase == Phase.MAIN and mood == Mood.ALERT):
		return 0.0                 # a short look; an alerted civilian stands and watches
	if phase == Phase.CALM:
		return 0.6
	return float(speeds.get(mood, 1.0))


func is_calm() -> bool:
	return mood == Mood.AMBIENT


func _distance() -> float:
	return watch_distance if mood == Mood.ALERT else flee_distance


func _set_phase(p: int, now: float) -> void:
	phase = p
	_phase_at = now
