class_name RtsAiPlayer
extends Node
## A computer player (recipe 64's RtsAiBrain with this game as its world): it keeps workers gathering (about 60% on
## gold, 40% on wood), follows its build order, builds farms before supply runs out, sends growing attack waves at the
## enemy's town hall and pulls them back when they lose. It sees through its own team's fog only.
## `player_bot` (tests) plays team 0 for the player with a counter-minded order (archers against footmen, riders
## later) and defends at home until its first wave is ready.
## Observable: brain, waves_sent().

@export var team := 1
@export var level := 1
@export var player_bot := false

const MAX_BARRACKS := 4

var brain := RtsAiBrain.new()
var game: RtsGame

var _t := 0.0
var _workers_t := 0.0


func _ready() -> void:
	game = get_parent() as RtsGame
	brain.world = self
	brain.apply_preset(level)
	brain.worker_kind = &"worker"
	brain.farm_kind = &"farm"
	brain.worker_target = 14
	brain.supply_margin = 4
	if player_bot:
		brain.build_order = [
			{"kind": &"barracks", "count": 1}, {"kind": &"archer", "count": 4}, {"kind": &"footman", "count": 3},
			{"kind": &"stable", "count": 1}, {"kind": &"rider", "count": 3}, {"kind": &"barracks", "count": 2},
			{"kind": &"archer", "count": 8}, {"kind": &"footman", "count": 8}, {"kind": &"rider", "count": 8},
			{"kind": &"barracks", "count": 3}, {"kind": &"archer", "count": 30},
		] as Array[Dictionary]
		brain.wave_size = 12
		brain.wave_growth = 2
	else:
		brain.build_order = [
			{"kind": &"barracks", "count": 1}, {"kind": &"footman", "count": 4}, {"kind": &"archer", "count": 2},
			{"kind": &"stable", "count": 1}, {"kind": &"rider", "count": 2}, {"kind": &"barracks", "count": 2},
			{"kind": &"footman", "count": 8}, {"kind": &"archer", "count": 6}, {"kind": &"rider", "count": 5},
			{"kind": &"barracks", "count": 3}, {"kind": &"footman", "count": 30},
		] as Array[Dictionary]


func waves_sent() -> int:
	return brain.waves_sent


func _physics_process(delta: float) -> void:
	if game == null or game.winner >= 0:
		return
	_workers_t -= delta
	if _workers_t <= 0.0:
		_workers_t = 1.0
		_idle_workers_to_work()
		_spend_the_bank()
	brain.tick(delta)


## Rich and every barracks busy: another barracks (up to MAX_BARRACKS), so the money becomes an army.
func _spend_the_bank() -> void:
	var s := game.stockpile(team)
	if s.amount(&"gold") < 700 or game.count(team, &"barracks") >= MAX_BARRACKS or pending(&"barracks") > 0:
		return
	for b in game.buildings:
		if b.team == team and b.kind == &"barracks" and b.finished and b.production.queue.is_empty():
			return
	if game.count(team, &"barracks") > 0 and can_afford(&"barracks"):
		order(&"barracks")


func _idle_workers_to_work() -> void:
	var on := {&"gold": 0, &"wood": 0}
	var idle: Array[RtsUnit] = []
	for u in game.units:
		if u.team != team or not u.is_worker():
			continue
		var o := u.orders.current()
		if o.is_empty():
			idle.append(u)
		elif o.kind == RtsOrders.Kind.GATHER:
			var m := o.target as RtsMine
			if m != null:
				on[m.kind] += 1
	for u in idle:
		var res: StringName = &"gold" if on[&"gold"] <= on[&"wood"] * 1.5 else &"wood"
		var n := game.nearest_resource(res, u.global_position)
		if n == null:
			res = &"wood" if res == &"gold" else &"gold"
			n = game.nearest_resource(res, u.global_position)
		var m := game.mine_of(n) if n != null else null
		if m != null:
			u.orders.give(RtsOrders.make(RtsOrders.Kind.GATHER, m.global_position, m))
			on[res] += 1


# ---- the world the brain sees (recipe 64's interface) ----

func count(kind: StringName) -> int:
	return game.count(team, kind)


func pending(kind: StringName) -> int:
	return game.pending(team, kind)


func supply_free() -> int:
	return game.stockpile(team).supply_free() - _queued_supply()


## What `kind` needs is being built now (the brain waits for it instead of jumping ahead).
func unlocking(kind: StringName) -> bool:
	for need in game.techs[team].missing(kind):
		if game.pending(team, need) > 0:
			return true
	return false


## The nearest visible enemy unit within 16 m of our buildings (Vector3.INF: none).
func threat() -> Vector3:
	var best := Vector3.INF
	var bd := INF
	for e in game.units:
		if e.team == team or not game.visible_to(team, e):
			continue
		for b in game.buildings:
			if b.team == team and b.edge_distance(e.global_position) < 16.0:
				var d := e.global_position.distance_to(game.bases[team])
				if d < bd:
					bd = d
					best = e.global_position
				break
	return best


func supply_maxed() -> bool:
	var s := game.stockpile(team)
	return s.supply_cap >= s.max_supply


func _queued_supply() -> int:
	var n := 0
	for b in game.buildings:
		if b.team == team:
			for i in b.production.queue.size():
				if i > 0 or not b.production.started:
					n += int(b.production.queue[i].supply)
	return n


func can_afford(kind: StringName) -> bool:
	var def := game.rules.unit(kind) if game.rules.is_unit(kind) else game.rules.building(kind)
	return game.stockpile(team).can_afford(def.get("cost", {}))


func available(kind: StringName) -> bool:
	return game.techs[team].available(kind)


func order(kind: StringName) -> bool:
	if game.rules.is_unit(kind):
		var best: RtsBuilding = null
		for b in game.buildings:
			if b.team == team and b.finished and b.trains().has(kind):
				if best == null or b.production.queue.size() < best.production.queue.size():
					best = b
		return best != null and best.production.queue.size() < 2 and game.train(best, kind)
	var cell := _site_for(kind)
	if cell == Vector2i(-1, -1):
		return false
	var worker := _free_worker()
	if worker == null:
		return false
	return game.try_build(team, kind, cell, [worker]) != null


## A free footprint near home, spiralling out from the town hall toward the middle of the map.
func _site_for(kind: StringName) -> Vector2i:
	var size: Vector2i = game.rules.building(kind).size
	var home_cell := game.grid.cell_of(home())
	var toward := Vector2i(1, -1) if team == 0 else Vector2i(-1, 1)
	for r in range(3, 12):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := home_cell + Vector2i(dx, dy) + toward * 2
				if game.why_not_place(team, kind, c) == "" and _keeps_a_path(c, size):
					return c
	return Vector2i(-1, -1)


## Leaves a one-cell gap around the footprint, so a base never walls its own units in.
func _keeps_a_path(c: Vector2i, size: Vector2i) -> bool:
	for cell in game.grid.cells(c - Vector2i(1, 1), size + Vector2i(2, 2)):
		if game.grid.occupied.has(cell):
			return false
	return true


func _free_worker() -> RtsUnit:
	var best: RtsUnit = null
	for u in game.units:
		if u.team == team and u.is_worker():
			var o := u.orders.current()
			var busy_building: bool = not o.is_empty() and o.kind == RtsOrders.Kind.BUILD
			if not busy_building and (best == null or u.global_position.distance_to(home()) < best.global_position.distance_to(home())):
				best = u
	return best


func army() -> Array:
	var out: Array = []
	for u in game.units:
		if u.team == team and not u.is_worker():
			out.append(u)
	return out


func power(list: Array) -> float:
	var p := 0.0
	for u in list:
		p += game.rules.value((u as RtsUnit).kind)
	return p


func enemy_power_near(at: Vector3) -> float:
	var p := 0.0
	for u in game.units:
		if u.team != team and not u.is_worker() and u.global_position.distance_to(at) < 14.0 and game.visible_to(team, u):
			p += game.rules.value(u.kind)
	return p


func army_centre() -> Vector3:
	var list := army()
	var pos: Array[Vector3] = []
	for u in list:
		pos.append((u as RtsUnit).global_position)
	return RtsGroupMove.centroid(pos) if not pos.is_empty() else home()


## A wave: the idle units go (at the start that is the whole army; while it is out, those who finished their fight).
func attack(list: Array, at: Vector3) -> void:
	_send(list.filter(func(u: RtsUnit) -> bool: return u.orders.idle()), at, RtsOrders.Kind.ATTACK_MOVE)


func retreat(list: Array, to: Vector3) -> void:
	_send(list, to, RtsOrders.Kind.MOVE)


func _send(list: Array, at: Vector3, kind: RtsOrders.Kind) -> void:
	if list.is_empty():
		return
	var pos: Array[Vector3] = []
	for u in list:
		pos.append((u as RtsUnit).global_position)
	var targets := RtsGroupMove.targets(pos, at, 1.4)
	for i in list.size():
		(list[i] as RtsUnit).orders.give(RtsOrders.make(kind, targets[i]))


func enemy_base() -> Vector3:
	var other := 1 - team
	for b in game.buildings:
		if b.team == other and b.kind == &"town_hall":
			return b.global_position
	for b in game.buildings:
		if b.team == other:
			return b.global_position
	return game.bases[other]


## Where the army gathers and retreats to: in front of the base toward the enemy (the base centre is the town hall).
func home() -> Vector3:
	var base: Vector3 = game.bases[team]
	return base + (game.bases[1 - team] - base).normalized() * 9.0
