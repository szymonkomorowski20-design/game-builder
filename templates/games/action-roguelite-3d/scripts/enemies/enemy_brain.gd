class_name EnemyBrain
extends RefCounted
## What a basic enemy is doing, without any 3D in it: chase → (in range) windup → strike → recover → chase.
## A hit staggers it only while chasing or recovering; a started telegraph always finishes, so the player can trust
## what they see. Drive with tick(delta, distance_to_target).

signal strike_started
signal state_changed(state: State)

enum State { CHASE, WINDUP, STRIKE, RECOVER, STAGGER }

const EPS := 1e-4

var attack_range := 1.5
var telegraph := 0.45
var strike := 0.12
var recover := 0.7
var stagger_time := 0.25

var state := State.CHASE
var gate := Callable()   ## optional: returns whether it may start an attack now (attack tokens)
var _t := 0.0


func configure(tuning: EnemyTuning) -> void:
	attack_range = tuning.attack_range
	telegraph = tuning.telegraph
	strike = tuning.strike
	recover = tuning.recover


func tick(delta: float, distance: float) -> void:
	_t += delta
	match state:
		State.CHASE:
			if distance <= attack_range and (not gate.is_valid() or gate.call()):
				_go(State.WINDUP)
		State.WINDUP:
			if _t + EPS >= telegraph:
				_go(State.STRIKE)
				strike_started.emit()
		State.STRIKE:
			if _t + EPS >= strike:
				_go(State.RECOVER)
		State.RECOVER:
			if _t + EPS >= recover:
				_go(State.CHASE)
		State.STAGGER:
			if _t + EPS >= stagger_time:
				_go(State.CHASE)


func hit() -> void:
	if state == State.CHASE or state == State.RECOVER:
		_go(State.STAGGER)


## Seconds in the current state (how far into its telegraph it is).
func elapsed() -> float:
	return _t


func wants_to_move() -> bool:
	return state == State.CHASE


func is_telegraphing() -> bool:
	return state == State.WINDUP


func _go(s: State) -> void:
	state = s
	_t = 0.0
	state_changed.emit(s)
