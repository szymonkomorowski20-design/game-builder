class_name RtsUnit
extends CharacterBody3D
## One unit of the skirmish: a worker, footman, archer or rider (its numbers are in RtsRules). It carries out its
## order queue (recipe 58): MOVE (ignores enemies — move means move), ATTACK, ATTACK_MOVE (fights what it meets),
## HOLD, STOP, GATHER (a worker's loop, recipe 59), BUILD (a worker at a site), PATROL.
## Idle or holding, it picks targets itself (recipe 63: whoever hits it first, units before buildings, only what its
## team sees) and gives up a chase beyond the leash. Units don't collide with each other: the navigation agent's
## avoidance keeps them apart, and gatherers switch it off on their loop (the StarCraft fix for jammed workers).
## Observable: team, kind, hp, alive, orders, target, gatherer, state_name().

signal died(unit: RtsUnit)

const WORLD := 1
const UNITS := 2
const LEASH := 12.0
const ACQUIRE_EXTRA := 3.0
const GIVE_UP_AFTER := 3                 ## fresh paths tried when stuck far from the goal before stopping there
const SCAN_EVERY := 0.25               ## s between target scans (staggered per unit; at once when the target dies)
const ANSWER_WINDOW := 5.0             ## s after a hit a unit with no unit to fight still answers that attacker

var team := 0
var kind: StringName = &""
var is_building := false
var alive := true
var hp := 1.0
var max_hp := 1.0
var radius := 0.4
var def := {}
var game: RtsGame
var orders := RtsOrders.new()
var gatherer: RtsGatherer
var target: Variant = null            ## Variant: it may be freed while held (a typed var refuses a freed instance)
var attacking_me: Variant = null
var kills := 0

var agent: NavigationAgent3D
var _cooldown := 0.0
var _chase_from := Vector3.INF
var _dest := Vector3.INF
var _stuck := 0.0
var _last_dist := INF
var _repaths := 0
var _think := 0.0
var _had_target := false
var _hit_at := -INF                    ## game time of the last hit (answer a seen attacker only for a while)
var _body: MeshInstance3D
var _order_gather: RtsResourceNode = null
var _sidestep := 0.0
var _sidestep_dir := Vector3.ZERO
var _walk_stuck := 0.0
var _walk_best := INF


func setup(g: RtsGame, t: int, k: StringName) -> void:
	game = g
	team = t
	kind = k
	def = g.rules.unit(k)
	max_hp = float(def.hp)
	_think = randf() * SCAN_EVERY               # staggered: a spawned army doesn't scan in one frame
	hp = max_hp
	radius = float(def.radius)
	collision_layer = UNITS
	collision_mask = WORLD
	add_to_group(&"units")
	add_to_group(&"team_%d" % t)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = radius
	cap.height = maxf(radius * 2.0 + 0.4, 1.2)
	shape.shape = cap
	shape.position.y = cap.height * 0.5
	add_child(shape)
	_body = RtsLook.unit_body(k, radius, RtsLook.team_colour(t))
	add_child(_body)
	agent = NavigationAgent3D.new()
	agent.radius = radius
	agent.max_speed = float(def.speed)
	agent.path_desired_distance = 0.6
	agent.target_desired_distance = 0.4
	agent.avoidance_enabled = true
	agent.neighbor_distance = 6.0
	agent.velocity_computed.connect(_on_velocity)
	add_child(agent)
	if def.has("carry"):
		gatherer = RtsGatherer.new()
		gatherer.carry = int(def.carry)
		gatherer.gather_time = float(def.gather_time)
		gatherer.max_wait = gatherer.gather_time * 2.0      # a slot frees within one gather; only a long queue moves on
		gatherer.stockpile = g.stockpile(t)
		gatherer.find_node = func(kind_: StringName, from: Vector3, busy: RtsResourceNode) -> RtsResourceNode: return g.nearest_resource(kind_, from, busy)
		gatherer.find_drop = func(from: Vector3) -> Vector3: return g.nearest_drop(t, from)
		gatherer.deposited.connect(func(res: StringName, n: int) -> void: g.on_deposit(t, res, n))
	orders.order_changed.connect(_on_order_changed)


func is_worker() -> bool:
	return gatherer != null


func state_name() -> String:
	var o := orders.current()
	if o.is_empty():
		return "fight" if target != null else "idle"
	return String(RtsOrders.Kind.keys()[o.kind]).to_lower()


func armour() -> Dictionary:
	return {"armour": def.armour, "armour_type": def.armour_type, "tags": def.tags}


func take_damage(amount: float, by: Node3D) -> void:
	if not alive:
		return
	hp -= amount
	attacking_me = by
	_hit_at = game.elapsed
	game.reveal_attacker(team, by)
	game.notify_attacked(team, global_position)
	if hp <= 0.0:
		_die()


func _die() -> void:
	alive = false
	orders.clear()
	if gatherer != null:
		gatherer.stop()
	game.on_unit_died(self)
	died.emit(self)
	queue_free()


func _on_order_changed(o: Dictionary) -> void:
	target = null
	_think = 0.0
	_chase_from = Vector3.INF
	_stuck = 0.0
	_last_dist = INF
	_repaths = 0
	if gatherer != null:
		var gathering: bool = not o.is_empty() and o.kind == RtsOrders.Kind.GATHER
		if not gathering:
			gatherer.stop()
			agent.avoidance_enabled = true


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	var o := orders.current()
	if o.is_empty():
		_idle(delta)
		return
	match o.kind:
		RtsOrders.Kind.MOVE:
			if _walk_to(o.at, delta):
				orders.done()
		RtsOrders.Kind.PATROL:                  # a patrol fights what it meets (an attack-move between its points)
			_scan(delta)
			_answer()
			if _valid(target):
				_fight(target, delta)
			elif _walk_to(o.at, delta):
				orders.done()
		RtsOrders.Kind.ATTACK:
			var t: Node3D = o.target
			if not _valid(t):
				orders.done()
			else:
				_fight(t, delta)
		RtsOrders.Kind.ATTACK_MOVE:
			_scan(delta)
			_answer()
			if _valid(target):
				_fight(target, delta)
			elif _walk_to(o.at, delta):
				orders.done()
		RtsOrders.Kind.HOLD:
			_scan(delta)
			if _valid(target) and _in_reach(target):
				_strike(target)
			_stand()
		RtsOrders.Kind.STOP:
			orders.done()
		RtsOrders.Kind.GATHER:
			_gather(o, delta)
		RtsOrders.Kind.BUILD:
			_build(o, delta)


## Idle: fight what comes near (not workers), chase within the leash, then go back.
func _idle(delta: float) -> void:
	if is_worker():
		_stand()
		return
	_scan(delta)
	_answer()                                   # (idle, it chases within the leash)
	if _valid(target):
		if _chase_from == Vector3.INF:
			_chase_from = global_position
		if RtsCombat.should_give_up(_chase_from, global_position, LEASH):
			var back := _chase_from
			target = null
			_chase_from = Vector3.INF
			orders.give(RtsOrders.make(RtsOrders.Kind.MOVE, back))
			return
		_fight(target, delta)
	else:
		_stand()


## No unit to fight (no target, or a building), and a seen attacker hit it in the last ANSWER_WINDOW s: it answers that
## attacker, even beyond its acquire range. Idle units, and units on attack-move or patrol. Without it an idle footman
## shot from 7.5 m stands still (acquire = range + 3 + radius), and melee units attack-moving into a base keep hitting a
## wall while archers behind it shoot them (found by the proof game Kamienna Marchia). An explicit attack order is kept.
func _answer() -> void:
	if (not _valid(target) or target is RtsBuilding) and game.elapsed - _hit_at <= ANSWER_WINDOW and _valid(attacking_me) and game.visible_to(team, attacking_me as Node3D):
		target = attacking_me


func _scan(delta: float) -> void:
	_think -= delta
	var lost := _had_target and not _valid(target)
	if _think > 0.0 and not lost:
		return                                   # no scan every frame: an army without targets would scan n² a frame
	_think = SCAN_EVERY * randf_range(0.8, 1.2)      # jitter: units that lost one target together drift apart again
	var acquire := float(def.range) + ACQUIRE_EXTRA + radius
	target = game.pick_target(self, acquire) as Node3D
	_had_target = _valid(target)


func _fight(t: Node3D, delta: float) -> void:
	if _in_reach(t):
		_stand()
		_face(t.global_position)
		_strike(t)
	else:
		_walk_to(t.global_position, delta, false)


func _strike(t: Node3D) -> void:
	if _cooldown > 0.0:
		return
	_cooldown = float(def.cooldown)
	var dmg := game.combat.damage(def.attack, t.call(&"armour"))
	if float(def.range) > 2.0:
		game.shoot_arrow(global_position + Vector3(0, 1.1, 0), t.global_position + Vector3(0, 0.8, 0))
	t.call(&"take_damage", dmg, self)
	if not bool(t.get(&"alive")):
		kills += 1


func _in_reach(t: Node3D) -> bool:
	return float(t.call(&"edge_distance", global_position)) <= float(def.range) + radius + 0.15


func extent() -> float:
	return radius


func edge_distance(p: Vector3) -> float:
	return maxf(Vector2(p.x - global_position.x, p.z - global_position.z).length() - radius, 0.0)


func _gather(o: Dictionary, delta: float) -> void:
	if gatherer == null:
		orders.done()
		return
	var node_obj: Object = o.target
	var mine := node_obj as RtsMine
	if mine != null and (gatherer.node != mine.node or gatherer.state == RtsGatherer.State.IDLE):
		gatherer.gather(mine.node)
		_order_gather = mine.node
		agent.avoidance_enabled = false          # gatherers don't jam each other
	gatherer.position = global_position
	var t := gatherer.target()
	var arrived := t == Vector3.INF
	if t != Vector3.INF:
		arrived = game.edge_distance_at(t, global_position) <= radius + 0.6
		if not arrived:
			_walk_to(game.approach_point(t, global_position, radius), delta, false)     # the near side, not the centre
		else:
			_stand()
	gatherer.tick(delta, arrived)
	if gatherer.state == RtsGatherer.State.IDLE:
		orders.done()


func _build(o: Dictionary, delta: float) -> void:
	var site := o.target as RtsBuilding
	if site == null or not is_instance_valid(site) or site.finished or not site.alive:
		orders.done()
		return
	if site.edge_distance(global_position) <= radius + 0.6:
		_stand()
		_face(site.global_position)
		site.construct(delta * float(def.get("build_rate", 1.0)))
		if site.finished:
			orders.done()
			if _order_gather != null and not _order_gather.is_spent() and orders.idle():
				var m := game.mine_of(_order_gather)
				if m != null:
					orders.give(RtsOrders.make(RtsOrders.Kind.GATHER, m.global_position, m))
	else:
		_walk_to(site.global_position, delta, false)


## Walks toward `to`. Returns true on arrival (close enough, or stuck close to it — the crowd rule).
func _walk_to(to: Vector3, delta: float, arrive: bool = true) -> bool:
	var flat_d := _flat(global_position).distance_to(_flat(to))
	if arrive and flat_d <= maxf(radius * 1.5, 0.5):
		_stand()
		return true
	if _dest == Vector3.INF or _dest.distance_to(to) > 0.5:
		_dest = to
		agent.target_position = to
	if flat_d < _last_dist - 0.05:
		_last_dist = flat_d
		_stuck = 0.0
	else:
		_stuck += delta
		if arrive and ((_stuck > 1.2 and flat_d < 3.0) or (_stuck > 4.0 and _repaths >= GIVE_UP_AFTER)):
			_stand()
			return true                          # pressed against others who arrived, or truly walled in: good enough
		if _stuck > 4.0:
			_stuck = 0.0                         # far from the goal (a jam at a corner): a fresh path, not a stop there
			_repaths += 1
			agent.target_position = to
	var next := to
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) > 0 and not agent.is_navigation_finished():
		next = agent.get_next_path_position()
	var d := _flat(next) - _flat(global_position)
	var v := Vector3(d.x, 0.0, d.y).normalized() * float(def.speed) if d.length() > 0.05 else Vector3.ZERO
	# No progress for a while (pressed into a corner, a tree, a crowd): step aside for a moment, then ask for a new path.
	if flat_d < _walk_best - 0.1:
		_walk_best = flat_d
		_walk_stuck = 0.0
	else:
		_walk_stuck += delta
	if _walk_stuck > 1.0 and _sidestep <= 0.0:
		_walk_stuck = 0.0
		_walk_best = flat_d
		_sidestep = 0.4
		var side := Vector3(-v.z, 0.0, v.x).normalized() if v.length() > 0.01 else Vector3.RIGHT
		_sidestep_dir = side * (1.0 if randf() < 0.5 else -1.0)
		agent.target_position = to
	if _sidestep > 0.0:
		_sidestep -= delta
		v = (_sidestep_dir - v.normalized() * 0.5).normalized() * float(def.speed)
	if agent.avoidance_enabled:
		agent.velocity = v
	else:
		_apply_velocity(v)
	if v != Vector3.ZERO:
		_face(global_position + v)
	return false


func _on_velocity(v: Vector3) -> void:
	if alive:
		_apply_velocity(v)


func _apply_velocity(v: Vector3) -> void:
	velocity.x = v.x
	velocity.z = v.z
	move_and_slide()


func _stand() -> void:
	_dest = Vector3.INF
	_walk_best = INF
	_walk_stuck = 0.0
	if agent.avoidance_enabled:
		agent.velocity = Vector3.ZERO
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()


func _face(p: Vector3) -> void:
	var d := Vector3(p.x - global_position.x, 0.0, p.z - global_position.z)
	if d.length() > 0.01:
		_body.rotation.y = atan2(-d.x, -d.z)


func _valid(t: Variant) -> bool:
	return t != null and is_instance_valid(t) and bool(t.get(&"alive"))


static func _flat(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)
