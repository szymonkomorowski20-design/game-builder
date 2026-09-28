class_name MilBot
extends RefCounted
## A test driver for the template's scenarios — not game AI. It plays with the real input actions (move_*, shoot, aim,
## reload, crouch, action) and aims the way a mouse would (`aim_at`, then pulls down against most of the recoil).
## It behaves like a careful player:
##   - it only shoots soldiers it can see, after a human reaction time, in short aimed bursts;
##   - hurt, it finds low cover that hides it from the soldiers it sees, crouches there and waits for its health to
##     come back, then stands up and fights again;
##   - nobody in sight for a while: it pushes toward the nearest soldier.
## A bot like this failing means the fight is unfair for a competent player: accuracy too high, too many shooters at
## once, spawns that hit it before it can react, cover that doesn't cover.

const FRAME := 1.0 / 60.0
const REACTION := 0.25          ## s from a soldier appearing to the first shot
const BURST := 0.3              ## s the trigger is held (≈ 4 rifle rounds)
const BURST_REST := 0.3         ## s between bursts: past first_shot_rest, so spread and the recoil pattern reset
const COMPENSATE := 0.8         ## fraction of the recoil the bot pulls back down
const HURT_BELOW := 0.5         ## health fraction where it takes cover
const HEALED_ABOVE := 0.95
const PUSH_AFTER := 3.0         ## s without a visible soldier before it advances
const AIM_ERROR_START := 2.5    ## degrees off when it starts tracking a soldier (a flick is not perfect)
const AIM_ERROR_SETTLED := 0.6  ## degrees off once settled on the target (a steady hand, not a sniper)
const AIM_SETTLE := 0.7         ## s to settle
const HEAD_WITHIN := 12.0       ## m — closer than this it goes for the head; further, centre mass

var sc: GbScenario
var m: MilMission
var p: MilPlayer
var counts := {}
var _held := {}
var _seen := {}                 ## soldier id → seconds visible
var _unseen := 0.0
var _target_id := 0
var _tracking := 0.0
var _jitter := Vector2.ZERO
var _jitter_left := 0.0
var _rng := RandomNumberGenerator.new()


func _init(scenario: GbScenario, mission: MilMission, rng_seed: int = 11) -> void:
	sc = scenario
	m = mission
	p = mission.player
	_rng.seed = rng_seed


func _count(key: StringName) -> void:
	counts[key] = counts.get(key, 0) + 1


func _press(action: StringName, on: bool) -> void:
	if bool(_held.get(action, false)) == on:
		return
	_held[action] = on
	if on:
		sc.hold(action)
	else:
		sc.release(action)


## Walks in a world direction (converted into the player's own frame, since input is relative to the view).
func steer(dir: Vector3) -> void:
	var local := dir.rotated(Vector3.UP, -p.yaw)
	_press(&"move_right", local.x > 0.35)
	_press(&"move_left", local.x < -0.35)
	_press(&"move_down", local.z > 0.35)
	_press(&"move_up", local.z < -0.35)


func stop() -> void:
	steer(Vector3.ZERO)


func release_all() -> void:
	for a in _held.keys():
		_press(a, false)


## Follows the navigation path to `point`. Stops there, on timeout, or when `interrupt` returns true.
func walk_to(point: Vector3, radius: float = 0.8, timeout: float = 25.0, interrupt: Callable = Callable()) -> bool:
	var t := 0.0
	var path := PackedVector3Array()
	var repath := 0.0
	var i := 0
	while t < timeout:
		if interrupt.is_valid() and interrupt.call():
			stop()
			return false
		var here := p.global_position
		if Vector2(point.x - here.x, point.z - here.z).length() <= radius:
			stop()
			return true
		repath -= FRAME
		if repath <= 0.0:
			repath = 0.5
			path = NavigationServer3D.map_get_path(p.get_world_3d().navigation_map, here, point, true)
			i = 0
		var next := point
		while i < path.size():
			var q := path[i]
			if Vector2(q.x - here.x, q.z - here.z).length() > 0.5:
				next = q
				break
			i += 1
		var d := next - here
		d.y = 0.0
		if d.length() > 0.05:
			p.aim_at(p.eye_position() + d.normalized() * 10.0)
		steer(d.normalized())
		await sc.wait_frames(1)
		t += FRAME
	stop()
	return false


## Soldiers the player can see (a clear line from the eye to the head or the chest).
func visible_soldiers() -> Array[MilSoldier]:
	var out: Array[MilSoldier] = []
	var space := p.get_world_3d().direct_space_state
	var eye := p.eye_position()
	for n in p.get_tree().get_nodes_in_group(&"soldiers"):
		var s := n as MilSoldier
		if s == null or not s.alive:
			continue
		for point in [s.head_point(), s.aim_point()]:
			var q := PhysicsRayQueryParameters3D.create(eye, point, MilPlayer.WORLD)
			if space.intersect_ray(q).is_empty():
				out.append(s)
				break
	return out


func nearest(list: Array[MilSoldier]) -> MilSoldier:
	var best: MilSoldier = null
	var best_d := INF
	for s in list:
		var d := s.global_position.distance_to(p.global_position)
		if d < best_d:
			best_d = d
			best = s
	return best


func alive_soldiers() -> Array[MilSoldier]:
	var out: Array[MilSoldier] = []
	for n in p.get_tree().get_nodes_in_group(&"soldiers"):
		var s := n as MilSoldier
		if s != null and s.alive:
			out.append(s)
	return out


## Fights until `done` returns true (or the timeout). Returns true when done.
func fight(done: Callable, timeout: float = 120.0) -> bool:
	var t := 0.0
	while t < timeout:
		if done.call():
			release_all()
			return true
		if not p.alive:
			release_all()
			_count(&"dead")
			await sc.wait_until(func() -> bool: return p.alive, 10.0)
			await sc.wait_frames(2)
			return false
		var hurt := p.health.current < p.tuning.max_health * HURT_BELOW
		var seen := visible_soldiers()
		if hurt and not seen.is_empty():
			t += await _take_cover(seen)
			continue
		if seen.is_empty():
			_unseen += FRAME
			_press(&"shoot", false)
			_press(&"aim", false)
			if p.crouching and not hurt:
				await sc.tap(&"crouch")
			if p.gun().ammo < p.gun().stats.magazine * 0.4 and not p.gun().is_reloading():
				await sc.tap(&"reload")
				_count(&"reload")
			if _unseen > PUSH_AFTER:
				var target := nearest(alive_soldiers())
				if target != null:
					_count(&"push")
					await walk_to(target.global_position, 3.0, 3.0, func() -> bool: return not visible_soldiers().is_empty() or done.call())
					t += 3.0
					_unseen = 0.0
					continue
			await sc.wait_frames(1)
			t += FRAME
			continue
		_unseen = 0.0
		t += await _shoot_at(nearest(seen))
	release_all()
	return false


## One aimed burst at `s` (after the reaction time the first time it is seen). Returns the seconds spent.
func _shoot_at(s: MilSoldier) -> float:
	var spent := 0.0
	stop()
	var id := s.get_instance_id()
	if not _seen.has(id):
		_seen[id] = true
		_press(&"aim", true)
		await sc.wait(REACTION)
		spent += REACTION
	_press(&"aim", true)
	if p.gun().ammo == 0:
		await sc.tap(&"reload")
		await sc.wait_until(func() -> bool: return not p.gun().is_reloading(), 3.0)
		return spent + 1.0
	_count(&"burst")
	var burst := 0.0
	_press(&"shoot", true)
	while burst < BURST and is_instance_valid(s) and s.alive:
		_aim_at_soldier(s)
		await sc.wait_frames(1)
		burst += FRAME
	_press(&"shoot", false)
	await sc.wait(BURST_REST)
	return spent + burst + BURST_REST


func _aim_at_soldier(s: MilSoldier) -> void:
	var space := p.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p.eye_position(), s.head_point(), MilPlayer.WORLD)
	var head_clear := space.intersect_ray(q).is_empty()
	var near := s.global_position.distance_to(p.global_position) < HEAD_WITHIN
	var point := s.head_point() if head_clear and near else s.aim_point()
	# Human-ish tracking: the error starts large on a new target and settles; it wanders every 0.1 s.
	if s.get_instance_id() != _target_id:
		_target_id = s.get_instance_id()
		_tracking = 0.0
	_tracking += FRAME
	_jitter_left -= FRAME
	if _jitter_left <= 0.0:
		_jitter_left = 0.1
		_jitter = Vector2.from_angle(_rng.randf() * TAU) * _rng.randf()
	var err := deg_to_rad(lerpf(AIM_ERROR_START, AIM_ERROR_SETTLED, clampf(_tracking / AIM_SETTLE, 0.0, 1.0)))
	var to := point - p.eye_position()
	var side := to.cross(Vector3.UP).normalized()
	var up := side.cross(to).normalized()
	var dist := to.length()
	p.aim_at(point + (side * _jitter.x + up * _jitter.y) * dist * tan(err))
	var kick := p.gun().kick_accumulated
	p.look(deg_to_rad(kick.x) * COMPENSATE, -deg_to_rad(kick.y) * COMPENSATE)


## Hurt with soldiers in sight: to the nearest low cover that hides a crouched player from all of them, crouch, wait
## until healed. No such cover: back away from them. Returns the seconds spent.
func _take_cover(seen: Array[MilSoldier]) -> float:
	_count(&"cover")
	_press(&"shoot", false)
	_press(&"aim", false)
	var spent := 0.0
	var space := p.get_world_3d().direct_space_state
	var zone := m.current_zone()
	var best: Variant = null
	var best_d := 12.0
	if zone != null:
		for c in zone.cover_points():
			var d := c.distance_to(p.global_position)
			if d >= best_d:
				continue
			var hides := true
			for s in seen:
				var q := PhysicsRayQueryParameters3D.create(c + Vector3(0, p.tuning.crouch_eye, 0), s.eye_position(), MilPlayer.WORLD)
				if space.intersect_ray(q).is_empty():
					hides = false
					break
			if hides:
				best_d = d
				best = c
	if best != null:
		await walk_to(best, 0.5, 4.0)
		spent += 1.0
	else:
		var away := Vector3.ZERO
		for s in seen:
			away += (p.global_position - s.global_position).normalized()
		_count(&"retreat")
		steer(away.normalized())
		await sc.wait(1.0)
		stop()
		spent += 1.0
	if not p.crouching:
		await sc.tap(&"crouch")
	var waited := 0.0
	while p.alive and p.health.current < p.tuning.max_health * HEALED_ABOVE and waited < 12.0:
		await sc.wait_frames(6)
		waited += FRAME * 6
	spent += waited
	if p.crouching:
		await sc.tap(&"crouch")
	return spent
