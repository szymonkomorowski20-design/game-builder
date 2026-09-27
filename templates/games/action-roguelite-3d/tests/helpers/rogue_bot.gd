class_name RogueBot
extends RefCounted
## A test driver for the template's scenarios — not game AI. It plays with the real input actions: walks with
## move_*, attacks with `attack`, and reacts to telegraphs the way a player is expected to: walks out of an area it
## is standing in and dashes in the last moment (sideways for a charge). A bot like this failing means a telegraph
## is unreadable, a dodge window is too short, or the numbers are too harsh.

const FRAME := 1.0 / 60.0
const LAST_MOMENT := 0.15      ## s before the strike when the bot commits to its dash

var sc: GbScenario
var run: RogueRun
var _held := {}


func _init(scenario: GbScenario, r: RogueRun) -> void:
	sc = scenario
	run = r


func steer(dir: Vector3) -> void:
	_press(&"move_right", dir.x > 0.3)
	_press(&"move_left", dir.x < -0.3)
	_press(&"move_down", dir.z > 0.3)
	_press(&"move_up", dir.z < -0.3)


func stop() -> void:
	steer(Vector3.ZERO)


func walk_to(point: Vector3, radius: float = 0.6, timeout: float = 8.0) -> bool:
	var t := 0.0
	while t < timeout:
		var d := point - run.player.global_position
		d.y = 0.0
		if d.length() <= radius:
			stop()
			return true
		steer(d.normalized())
		await sc.wait_frames(1)
		t += FRAME
	stop()
	return false


func nearest_enemy() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for n in run.get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Node3D
		if e == null or e.is_queued_for_deletion():
			continue
		var d := e.global_position.distance_to(run.player.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


## Fights the nearest enemy (walk into reach, attack) until `done` returns true, reacting to telegraphs.
func fight_until(done: Callable, timeout: float = 60.0) -> bool:
	var t := 0.0
	while t < timeout:
		if done.call():
			stop()
			return true
		var reacted: bool = await _react_to_boss()
		if not reacted:
			reacted = await _react_to_enemies()
		if reacted:
			t += FRAME * 3
			continue
		var e := nearest_enemy()
		if e == null:
			stop()
			await sc.wait_frames(1)
			t += FRAME
			continue
		var d := e.global_position - run.player.global_position
		d.y = 0.0
		var reach := 2.3 if e is RogueBoss else 1.5
		if d.length() > reach:
			steer(d.normalized())
			await sc.wait_frames(1)
			t += FRAME
		else:
			stop()
			await sc.tap(&"attack")
			t += FRAME * 3
	stop()
	return false


func _react_to_boss() -> bool:
	if run.room == null or not is_instance_valid(run.room.boss) or run.room.boss.is_queued_for_deletion():
		return false
	var boss := run.room.boss
	if not boss.brain.is_telegraphing():
		return false
	var a := boss.brain.current_attack()
	var left := a.telegraph - boss.brain.state_elapsed()
	var from_boss := run.player.global_position - boss.global_position
	from_boss.y = 0.0
	if a.id == &"lunge":
		if left > LAST_MOMENT or from_boss.length() > boss.lunge_speed * a.strike + 2.0:
			return false
		var side := Vector3(-from_boss.z, 0.0, from_boss.x).normalized()
		return await _dash(side)
	var radius := boss.slam_radius if a.id == &"slam" else boss.nova_radius
	if from_boss.length() > radius + 0.8:
		return false
	var out := from_boss.normalized() if from_boss.length() > 0.1 else Vector3.BACK
	if left <= LAST_MOMENT and from_boss.length() <= radius + 0.3:
		return await _dash(out)
	steer(out)
	await sc.wait_frames(3)
	return true


## A basic enemy next to the hero is about to strike: dash away in the last moment — or walk away if the dash is
## still cooling down. Checks every telegraphing enemy, not just the first one found.
func _react_to_enemies() -> bool:
	for n in run.get_tree().get_nodes_in_group(&"enemies"):
		var e := n as RogueEnemy
		if e == null or not e.brain.is_telegraphing():
			continue
		var away := run.player.global_position - e.global_position
		away.y = 0.0
		if away.length() > e.tuning.attack_range * 1.3 or e.tuning.telegraph - e.brain.elapsed() > LAST_MOMENT:
			continue
		var dir := away.normalized() if away.length() > 0.1 else Vector3.BACK
		if await _dash(dir):
			return true
		steer(dir)
		await sc.wait_frames(3)
		return true
	return false


func _dash(dir: Vector3) -> bool:
	if not run.player.dash.is_ready():
		return false
	steer(dir)
	await sc.tap(&"dash")
	return true


func _press(action: StringName, on: bool) -> void:
	if on == _held.get(action, false):
		return
	_held[action] = on
	if on:
		sc.hold(action)
	else:
		sc.release(action)
