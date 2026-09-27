class_name RogueBot
extends RefCounted
## A test driver for the template's scenarios — not game AI. It plays with the real input actions: walks with
## move_*, attacks with `attack`, and reacts to telegraphs the way a player is expected to: walks out of an area it
## is standing in and dashes in the last moment (sideways for a charge). Like a careful
## player it does not start a swing when a strike is about to land (a swing's windup/active can't be dash-cancelled),
## and with several enemies striking it dashes away from all of them. A bot like this failing means a telegraph is
## unreadable, a dodge window is too short, or the numbers are too harsh.

const FRAME := 1.0 / 60.0
const LAST_MOMENT := 0.15      ## s before the strike when the bot commits to its dash
const HOLD_FIRE := 0.35        ## s — no new swing when a strike lands sooner than this

var sc: GbScenario
var run: RogueRun
var _held := {}
var counts := {}   ## how often each decision was taken (diagnosis)


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
			counts[&"reacted"] = counts.get(&"reacted", 0) + 1
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
		# The sword's hitbox reaches 1.6 m ahead plus the target's radius, so 1.8 m is still in reach.
		var reach := 2.3 if e is RogueBoss else 1.8
		if d.length() > reach:
			counts[&"approach"] = counts.get(&"approach", 0) + 1
			steer(d.normalized())
			await sc.wait_frames(1)
			t += FRAME
		elif _soonest_strike() < HOLD_FIRE:
			counts[&"hold_fire"] = counts.get(&"hold_fire", 0) + 1
			steer(-d.normalized())        # step back instead of committing to a swing
			await sc.wait_frames(1)
			t += FRAME
		else:
			counts[&"attack"] = counts.get(&"attack", 0) + 1
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


## Melee enemies next to the hero that are about to strike: in the last moment, dash away from all of them (their
## centre) — or walk away if the dash can't be used now.
func _react_to_enemies() -> bool:
	var threats := _melee_threats()
	if threats.is_empty() or _soonest_strike() > LAST_MOMENT:
		return false
	var centre := Vector3.ZERO
	for e in threats:
		centre += e.global_position
	centre /= threats.size()
	var away := run.player.global_position - centre
	away.y = 0.0
	var dir := away.normalized() if away.length() > 0.1 else Vector3.BACK
	if await _dash(dir):
		counts[&"dash_melee"] = counts.get(&"dash_melee", 0) + 1
		return true
	counts[&"walk_melee"] = counts.get(&"walk_melee", 0) + 1
	steer(dir)
	await sc.wait_frames(3)
	return true


## Telegraphing melee enemies close enough to hit the hero.
func _melee_threats() -> Array[RogueEnemy]:
	var out: Array[RogueEnemy] = []
	for n in run.get_tree().get_nodes_in_group(&"enemies"):
		var e := n as RogueEnemy
		if e == null or not e.brain.is_telegraphing():
			continue
		var d := run.player.global_position.distance_to(e.global_position)
		if d <= e.tuning.attack_range * 1.3:
			out.append(e)
	return out


## Seconds until the first of those strikes lands (INF when none).
func _soonest_strike() -> float:
	var soonest := INF
	for e in _melee_threats():
		soonest = minf(soonest, e.tuning.telegraph - e.brain.elapsed())
	return soonest


## Test setup: removes every enemy and pending spawn from a chamber, so a scenario can place exactly what it tests.
static func clear_room(room: RogueRoom) -> void:
	for e in room.alive_enemies():
		e.queue_free()
	for p in room._pending:
		(p.mark as Node).queue_free()
	room._pending.clear()


func _dash(dir: Vector3) -> bool:
	var phase := run.player.melee.combo.phase
	if not run.player.dash.is_ready() or phase == ComboAttack.Phase.WINDUP or phase == ComboAttack.Phase.ACTIVE:
		return false   # a committed swing can't be dashed out of
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
