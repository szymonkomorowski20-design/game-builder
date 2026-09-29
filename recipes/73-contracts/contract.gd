class_name Contract
extends RefCounted
## One assassination contract in phases (recipe 73, genre doc §9): APPROACH (find the target, strike) → ESCAPE (the
## target is down; lose the chase or reach the exit) → DONE. Detection never fails it: detection changes the situation
## (the alerted target flees, the chase starts) instead of ending the mission. It fails only when the target reaches
## safety or the player dies. Optional objectives — unseen, only the target — are bonuses reported at the end; they
## never fail anything and must not dictate the style of play.

enum Phase { BRIEFED, APPROACH, ESCAPE, DONE, FAILED }

var id: StringName
var phase: int = Phase.BRIEFED
var detected := false
var target_alerted := false
var extra_kills := 0
var fail_reason := ""
var started_at := 0.0
var finished_at := 0.0


func _init(p_id: StringName = &"") -> void:
	id = p_id


func start(now: float) -> void:
	phase = Phase.APPROACH
	started_at = now


## The player was detected: the target is alerted (the host makes it run for its safe place); nothing fails.
func on_detected() -> void:
	detected = true
	if phase == Phase.APPROACH:
		target_alerted = true


func on_kill(is_target: bool) -> void:
	if not is_target:
		extra_kills += 1
		return
	if phase == Phase.APPROACH:
		phase = Phase.ESCAPE


## The chase was lost (recipe 72's WantedSearch escaped) or the exit reached.
func on_escaped(now: float) -> void:
	if phase == Phase.ESCAPE:
		phase = Phase.DONE
		finished_at = now


func on_target_safe() -> void:
	if phase == Phase.APPROACH:
		_fail("the target reached safety")


func on_player_died() -> void:
	if phase == Phase.APPROACH or phase == Phase.ESCAPE:
		_fail("the player died")


func bonuses() -> Dictionary:
	return {unseen = not detected, only_the_target = extra_kills == 0}


func is_over() -> bool:
	return phase == Phase.DONE or phase == Phase.FAILED


func _fail(reason: String) -> void:
	phase = Phase.FAILED
	fail_reason = reason
