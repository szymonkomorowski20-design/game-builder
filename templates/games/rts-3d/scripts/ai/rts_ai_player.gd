class_name RtsAiPlayer
extends Node
## A computer player (recipe 64's RtsAiBrain with this game as its world): it keeps workers gathering (about 60% on
## gold, 40% on wood), follows its build order, builds farms before supply runs out, sends growing attack waves at the
## enemy's town hall and pulls them back when they lose. It sees through its own team's fog only.
## `player_bot` (tests) plays team 0 for the player: after its opening it reads the enemy's army (only what its team
## sees) and trains the counter; it defends at home until its first wave is ready.
## Habits measured in the proof game Kamienna Marchia: farms ahead of the army, production that never idles, the
## difficulty's production cap, and a threat that is an enemy on our half.
## Observable: brain, waves_sent(), counter_kind.

@export var team := 1
@export var level := 1
@export var player_bot := false

const MAX_BARRACKS := 4                    ## the player's bot; the computer: its difficulty's `production`
const SUPPLY_MARGIN := 4                   ## food kept free ahead of the army with no barracks (recipe 64's margin)
const SUPPLY_PER_BARRACKS := 3             ## … and this much more per barracks (each one trains without a break)
const FARM_WOOD_EACH := 2                  ## farms at once: one more for every this many farms' wood in the bank …
const MAX_FARMS_AT_ONCE := 3               ## … up to this many
const FILLER_RESERVE := 300               ## gold kept for the order's next step before an idle production building trains

@export var attack_enabled := true             ## false: it builds and defends at home but sends no waves (a mission bot)
@export var opening: Array[Dictionary] = []    ## player_bot: its build order before it reads the enemy (empty: the default)
@export var first_wave_not_before := 240.0     ## s: no wave leaves home before (every difficulty; the genre's rush pitfall)

var brain := RtsAiBrain.new()
var game: RtsGame

var _t := 0.0
var _workers_t := 0.0
var _opening: Array[Dictionary] = []
var max_barracks := MAX_BARRACKS
var counter_kind: StringName = &"archer"      ## player_bot: what it trains against what it has seen
var _seen := {}                                ## player_bot: enemy army kind → how many it saw at once, at most

const COUNTER := {&"footman": &"archer", &"archer": &"rider", &"rider": &"footman"}


func _ready() -> void:
	game = get_parent() as RtsGame
	brain.world = self
	brain.apply_preset(level)
	brain.first_wave_not_before = first_wave_not_before if attack_enabled else INF
	brain.cap_first_wave = true
	brain.worker_kind = &"worker"
	brain.farm_kind = &"farm"
	brain.worker_target = 14
	brain.supply_margin = SUPPLY_MARGIN
	if player_bot and not opening.is_empty():
		_opening = opening.duplicate()
		brain.build_order = _opening.duplicate()
	elif player_bot:
		_opening = [
			{"kind": &"barracks", "count": 1}, {"kind": &"archer", "count": 4}, {"kind": &"footman", "count": 3},
			{"kind": &"stable", "count": 1}, {"kind": &"barracks", "count": 2},
		] as Array[Dictionary]
		brain.build_order = _opening.duplicate()
		brain.wave_size = 12
		brain.wave_growth = 2
	else:
		max_barracks = int(RtsAiBrain.preset(level).get("production", MAX_BARRACKS))
		brain.build_order = [
			{"kind": &"barracks", "count": 1}, {"kind": &"footman", "count": 4}, {"kind": &"archer", "count": 2},
			{"kind": &"stable", "count": 1}, {"kind": &"rider", "count": 2}, {"kind": &"barracks", "count": 2},
			{"kind": &"footman", "count": 8}, {"kind": &"archer", "count": 6}, {"kind": &"rider", "count": 5},
			{"kind": &"barracks", "count": 3}, {"kind": &"footman", "count": 30},
		] as Array[Dictionary]
		for step in brain.build_order:
			if step.kind == &"barracks":
				step.count = mini(int(step.count), max_barracks)      # its difficulty's production


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
		if player_bot:
			_read_the_enemy()
	brain.tick(delta)


## player_bot: the counter to the enemy kind it has seen most of (only what its team sees), trained after its opening.
## A player who reads the enemy's army beats a computer with a fixed order: the counter triangle at work.
func _read_the_enemy() -> void:
	var now := {}
	for u in game.units:
		if u.team != team and not u.is_worker() and game.visible_to(team, u):
			now[u.kind] = int(now.get(u.kind, 0)) + 1
	for k in now:
		_seen[k] = maxi(int(_seen.get(k, 0)), int(now[k]))
	var best: StringName = &""
	for k in _seen:
		if best == &"" or int(_seen[k]) > int(_seen[best]):
			best = k
	if best != &"":
		counter_kind = COUNTER.get(best, &"archer")
	var kind := counter_kind
	var farm_wood := int(game.rules.building(&"farm").cost.get(&"wood", 0))
	var footman_gold := int(game.rules.unit(&"footman").cost.get(&"gold", 0))
	if not can_afford(kind) and game.stockpile(team).amount(&"wood") < farm_wood and game.stockpile(team).amount(&"gold") >= footman_gold:
		kind = &"footman"                        # out of wood with gold in the bank: the gold-only soldier
	var tail: Array[Dictionary] = [{"kind": kind, "count": count(kind) + 2}, {"kind": &"barracks", "count": 3}]
	brain.build_order = _opening + tail


## The money becomes an army. Farms ahead: the margin of free food grows with the barracks, and with wood in the bank
## more farms go up at once (one more per FARM_WOOD_EACH farms' wood, up to MAX_FARMS_AT_ONCE). In the proof game Kamienna
## Marchia the brain's one farm at a time left every difficulty food-capped by 6 minutes, the hard one with 5000 gold unspent, so a
## difficulty's income bought nothing. Rich and every barracks busy: another barracks (up to `max_barracks`).
func _spend_the_bank() -> void:
	var s := game.stockpile(team)
	brain.supply_margin = SUPPLY_MARGIN + SUPPLY_PER_BARRACKS * game.count(team, &"barracks")
	var farm_wood := int(game.rules.building(&"farm").cost.get(&"wood", 0))
	var at_once := clampi(s.amount(&"wood") / maxi(1, FARM_WOOD_EACH * farm_wood), 1, MAX_FARMS_AT_ONCE)
	if s.supply_cap < s.max_supply and supply_free() < brain.supply_margin and pending(&"farm") >= 1 \
			and pending(&"farm") < at_once and can_afford(&"farm"):
		order(&"farm")
	_keep_production_busy()
	if s.amount(&"gold") < 700 or game.count(team, &"barracks") >= max_barracks or pending(&"barracks") > 0:
		return
	for b in game.buildings:
		if b.team == team and b.kind == &"barracks" and b.finished and b.production.queue.is_empty():
			return
	if game.count(team, &"barracks") > 0 and can_afford(&"barracks"):
		order(&"barracks")


## Production never idles while the order waits (for a building on its way, or for the money it saves): an idle
## building that trains soldiers, with food free and gold past FILLER_RESERVE, trains one — the player's bot its counter
## when that building makes it, otherwise (and the computer always) the kind the army has fewer of. (Kamienna Marchia: waiting
## 90 s for its stable, a computer trained nothing and banked 2400 gold; the same difficulty fielded 22 or 33 soldiers
## at 6 minutes depending on the seed.)
func _keep_production_busy() -> void:
	var s := game.stockpile(team)
	for b in game.buildings:
		if b.team != team or not b.finished or b.production == null or not b.production.queue.is_empty():
			continue
		var kinds: Array = b.trains().filter(func(k: StringName) -> bool: return k != brain.worker_kind)
		if kinds.is_empty():
			continue
		var k: StringName = kinds[0]
		if player_bot and kinds.has(counter_kind):
			k = counter_kind
		else:
			for other: StringName in kinds:
				if count(other) < count(k):
					k = other
		var cost: Dictionary = game.rules.unit(k).cost
		if s.amount(&"gold") - int(cost.get(&"gold", 0)) < FILLER_RESERVE or supply_free() < int(game.rules.unit(k).supply) or not can_afford(k):
			return
		game.train(b, k)


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


## The nearest visible enemy unit on our half of the map within 16 m of our buildings (Vector3.INF: none). Both sides' buildings
## spread toward each other; without the half, an army idling at its own rally was a "threat" and the whole army went
## at it (the proof game Kamienna Marchia: the bot lost its third mission on 2 of 4 seeds that way).
func threat() -> Vector3:
	var best := Vector3.INF
	var bd := INF
	for e in game.units:
		if e.team == team or not game.visible_to(team, e):
			continue
		if e.global_position.distance_to(game.bases[team]) >= e.global_position.distance_to(game.bases[1 - team]):
			continue                             # on its own half: an army idling at home is no threat
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


## The units the brain may send: every soldier (a game with a start garrison leaves it out here).
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


## Where these units are (a wave): the brain measures the enemy near its wave, not near the whole army.
func centre_of(list: Array) -> Vector3:
	var pos: Array[Vector3] = []
	for u in list:
		if is_instance_valid(u):
			pos.append((u as RtsUnit).global_position)
	return RtsGroupMove.centroid(pos) if not pos.is_empty() else home()


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


## Where the enemy is, as far as this team knows: a town hall it has seen, else any building it has seen, else the
## enemy's start (known on a two-player map, as in the genre). Never a building it hasn't seen.
func enemy_base() -> Vector3:
	var other := 1 - team
	for b in game.buildings:
		if b.team == other and b.kind == &"town_hall" and b.seen_by.has(team):
			return b.global_position
	for b in game.buildings:
		if b.team == other and b.seen_by.has(team):
			return b.global_position
	return game.bases[other]


## Where the army gathers and retreats to: in front of the base toward the enemy (the base centre is the town hall).
func home() -> Vector3:
	var base: Vector3 = game.bases[team]
	return base + (game.bases[1 - team] - base).normalized() * 9.0
