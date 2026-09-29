class_name GuardAgent
extends CharacterBody3D
## A guard (template stealth-parkour-3d): recipe 68's senses at eye height, recipe 69's brain on the game's shared board,
## walking on the navigation mesh, and recipe 71's strikes when it fights. It turns its whole body (the senses look
## along its −Z). Dead, it leaves a body that other guards find.

signal died(guard: GuardAgent)

@export var walk_speed := 1.6
@export var run_speed := 4.6
@export var turn_speed := 6.0
@export var max_health := 3
@export var fight_reach := 2.0
@export var body_sight := 14.0

var game: StealthGame
var guard_name: StringName = &""
var brain: GuardBrain
var route: Array[Vector3] = []
var facing := Vector3.FORWARD
var heavy := false
var health := 3
var alive := true
var strikes := 0
var stagger_until := -INF
var strike: EnemyStrike = null
var strike_start := 0.0

var _route_i := 0
var _hits_done := 0
var _bodies_seen := {}
var _nav_target := Vector3.INF

@onready var senses: GuardSenses = $Senses
@onready var agent: NavigationAgent3D = $Agent
@onready var mark: Label3D = $Mark
@onready var meter_bar: MeshInstance3D = $Meter
@onready var body: Node3D = $Body


func setup(p_game: StealthGame, p_name: StringName, post: Vector3, p_facing: Vector3, p_route: Array[Vector3],
		p_heavy: bool = false) -> void:
	game = p_game
	guard_name = p_name
	name = String(p_name)
	route = p_route
	facing = Vector3(p_facing.x, 0.0, p_facing.z).normalized()
	heavy = p_heavy
	brain = GuardBrain.new(game.board, post)
	brain.search_candidates = DistrictMap.search_points()
	brain.hidden_from = game.hidden_from
	health = max_health + (1 if heavy else 0)
	global_position = post
	rotation.y = atan2(-facing.x, -facing.z)
	senses.target_path = senses.get_path_to(game.player)


func _physics_process(delta: float) -> void:
	if not alive or game == null:
		return
	var now := game.clock
	senses.guard_state = brain.guard_state(now)
	senses.notice_scale = game.notice_scale()
	var p := game.player
	var seen := senses.seen and p.alive
	_look_for_bodies(now)
	# seen_at: where the player was at the senses' last look (not live: the look is up to think_every old).
	brain.tick(now, {level = senses.meter.level(), seen = seen, seen_at = senses.meter.last_seen,
			true_pos = p.global_position}, _position_for_brain())
	if brain.wants_reset:
		senses.meter.reset()
		brain.wants_reset = false
	if seen and brain.state == GuardBrain.State.ALERT:
		game.player_seen_by(self)
	_fight(now)
	_move(delta, now)
	_update_mark()


## A noise of `radius` m at `at` (`key`: one investigator per noise, recipe 69).
func hear_noise(at: Vector3, radius: float, key: String) -> void:
	if not alive:
		return
	if Hearing.hears(radius, Hearing.distance(get_world_3d().navigation_map, at, global_position)):
		brain.notice(&"noise", key, at, game.clock)


func is_hunting() -> bool:
	return brain.state == GuardBrain.State.ALERT or brain.state == GuardBrain.State.SEARCH


## Hit by the player: `n` hits off the health, and a stagger that also breaks its own strike.
func take_hit(n: int, stagger: float) -> void:
	if not alive:
		return
	health -= n
	stagger_until = game.clock + stagger
	_end_strike()
	if health <= 0:
		die()
	elif not is_hunting():
		senses.meter.value = 1.0
		senses.meter.detected = true


func die() -> void:
	if not alive:
		return
	alive = false
	_end_strike()
	game.stage.disengage(self)
	game.board.leave_search(brain)
	if not brain.stimulus().is_empty():
		game.board.release_investigation(brain.stimulus().key, brain)
	collision_layer = 0
	collision_mask = 1
	body.rotation.x = -PI * 0.5
	body.position.y = 0.3
	mark.visible = false
	meter_bar.visible = false
	add_to_group(&"body")
	died.emit(self)


func _fight(now: float) -> void:
	var p := game.player
	var d := _flat(p.global_position - global_position).length()
	var engaged := brain.state == GuardBrain.State.ALERT and p.alive and d <= fight_reach + 1.5
	if engaged:
		game.stage.engage(self, 8 if heavy else 4)
	elif strike == null:
		game.stage.disengage(self)
	if strike != null:
		var times := strike.hit_times(strike_start)
		while strike != null and _hits_done < times.size() and now >= times[_hits_done]:
			_hits_done += 1
			if d <= fight_reach + 0.6:
				game.resolve_strike(self, strike.kind)   # a counter ends the strike (take_hit → _end_strike)
		if strike != null and now >= strike_start + strike.duration():
			_end_strike()
		return
	if engaged and now >= stagger_until and d <= fight_reach and game.stage.may_attack(self, 2, now):
		strikes += 1
		var kind := EnemyStrike.Kind.UNBLOCKABLE if heavy and strikes % 2 == 0 else EnemyStrike.Kind.NORMAL
		strike = EnemyStrike.make(kind)
		strike_start = now
		_hits_done = 0
		game.strike_started(self, strike)


func _end_strike() -> void:
	if strike != null:
		strike = null
		game.stage.attack_done(self)


func _move(delta: float, now: float) -> void:
	var goal := brain.goal
	var speed := run_speed if brain.running else walk_speed
	var look := Vector3.ZERO
	if brain.state == GuardBrain.State.PATROL:
		speed = walk_speed
		if route.is_empty():
			goal = brain.post
			look = facing
		else:
			if _flat(route[_route_i] - global_position).length() < 0.6:
				_route_i = (_route_i + 1) % route.size()
			goal = route[_route_i]
	elif brain.state == GuardBrain.State.SUSPICIOUS or brain.state == GuardBrain.State.INVESTIGATE:
		look = _flat(brain.look_at - global_position)
	var p := game.player
	if brain.state == GuardBrain.State.ALERT and _flat(p.global_position - global_position).length() <= fight_reach:
		goal = global_position
		look = _flat(p.global_position - global_position)
	var planar := Vector3.ZERO
	if now >= stagger_until and strike == null and _flat(goal - global_position).length() > 0.5:
		if _nav_target.distance_to(goal) > 0.5:
			agent.target_position = goal
			_nav_target = goal
		var next := agent.get_next_path_position()
		var dir := _flat(next - global_position)
		if dir.length() > 0.05:
			planar = dir.normalized() * speed
			look = planar
	velocity.x = planar.x
	velocity.z = planar.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	if look.length_squared() > 1e-4:
		rotation.y = rotate_toward(rotation.y, atan2(-look.x, -look.z), turn_speed * delta)


## Where the brain thinks the guard is. A goal off the navigation mesh (a spot on a stall, a point in a wall) is
## reached when the path is done as close as the mesh allows; without this the guard would never "arrive" there.
func _position_for_brain() -> Vector3:
	if (brain.state != GuardBrain.State.PATROL and _nav_target.distance_to(brain.goal) < 0.5
			and agent.is_navigation_finished() and _flat(brain.goal - global_position).length() < 3.0):
		return brain.goal
	return global_position


func _look_for_bodies(now: float) -> void:
	for b: Node in get_tree().get_nodes_in_group(&"body"):
		if b == self or _bodies_seen.has(b.get_instance_id()):
			continue
		var at := (b as Node3D).global_position
		if at.distance_to(global_position) > body_sight:
			continue
		if senses.cone.zone(senses.global_position, -global_transform.basis.z, at + Vector3.UP * 0.3) == &"":
			continue
		if not game.hidden_from.call(senses.global_position, at + Vector3.UP * 0.3):
			_bodies_seen[b.get_instance_id()] = true
			brain.notice(&"body", "body:" + String(b.name), at, now)


func _update_mark() -> void:
	var v := senses.meter.value
	if is_hunting():
		mark.text = "!"
		mark.modulate = Color(1, 0.2, 0.15)
	elif (brain.state == GuardBrain.State.SUSPICIOUS or brain.state == GuardBrain.State.INVESTIGATE
			or v >= senses.meter.suspicious_at):
		mark.text = "?"
		mark.modulate = Color(1, 0.85, 0.2)
	else:
		mark.text = ""
	meter_bar.visible = v > 0.01 and not is_hunting()
	meter_bar.scale.x = maxf(v, 0.01)


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
