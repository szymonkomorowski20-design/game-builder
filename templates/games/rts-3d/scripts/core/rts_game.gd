class_name RtsGame
extends Node3D
## The skirmish (the main scene's root): two teams — 0 the player, 1 the computer — each with a town hall and
## workers, gold mines and trees, on a map built by RtsMap. It owns what the teams share and the rules between them:
##   - per team: the stockpile and supply (recipe 59), the tech tree (60), the fog of war (62);
##   - the placement grid (60), combat rules (63), the navigation mesh (rebuilt when buildings change);
##   - spawning units and buildings, production, deaths, and the winner (the last team with buildings).
## The player's hands are RtsPlayerInput, the opponent is RtsAiPlayer (recipe 64); tests can hand team 0 to an AI too
## (`bot_team`). Observable: winner, elapsed, units, buildings, mines, stockpile(t), fog(t), count(t, kind).

signal game_over(winner: int)
signal message(text: String)                   ## a short line for the player (HUD)
signal alert(at: Vector3)                      ## the player's things are under attack there

@export var rules: RtsRules
@export var ai_level := 1                      ## 0 easy · 1 normal · 2 hard (recipe 64's presets)
@export var bot_team := -1                     ## tests: a team the computer plays for the player (−1: none)
@export var fog_rate := 10.0                   ## fog updates per second, one team each (so each team's at half this)
@export var ai_enabled := true                 ## tests: a sandbox without the computer player
@export var reveal_map := false                ## tests and the end screen: everything explored for the player

var stockpiles: Array[RtsStockpile] = []
var techs: Array[RtsTechTree] = []
var fogs: Array[RtsFog] = []
var grid: RtsBuildGrid
var combat := RtsCombat.new()
var units: Array[RtsUnit] = []
var buildings: Array[RtsBuilding] = []
var mines: Array[RtsMine] = []
var winner := -1
var elapsed := 0.0
var income_multiplier: Array[float] = [1.0, 1.0]
var bases: Array[Vector3] = []
var props: Array[Node3D] = []                  ## rocks: drawn once the player has explored them

var nav: NavigationRegion3D
var _fog_t := 0.0
var _fog_team := 0
var _rebake := false
var _alert_cool := 0.0

@onready var world_root: Node3D = $World


func _ready() -> void:
	if rules == null:
		rules = RtsRules.new()
	combat.table = rules.type_table
	for t in 2:
		var s := RtsStockpile.new(rules.start)
		s.max_supply = rules.max_supply
		stockpiles.append(s)
		techs.append(RtsTechTree.new(rules.tech_table()))
		fogs.append(RtsFog.new(36, 36, 2.0, Vector3(-36, 0, -36)))      # 2 m cells: a battle of 80 costs ~1/4 of 1 m cells
	grid = RtsBuildGrid.new()
	grid.cell_size = rules.cell_size
	grid.width = 36
	grid.height = 36
	grid.origin = Vector3(-36, 0, -36)
	nav = RtsMap.build(self)
	for t in 2:
		var base: Vector3 = bases[t]
		var hall := place_building(t, &"town_hall", grid.footprint_at(base, rules.building(&"town_hall").size), true)
		hall.rally_point = base + (Vector3(4, 0, -4) if t == 0 else Vector3(-4, 0, 4))
		for i in rules.start_workers:
			spawn_unit(t, &"worker", base + Vector3(-3.0 + i * 1.5, 0, 3.5 if t == 0 else -3.5))
	nav.bake_navigation_mesh(false)
	if reveal_map:
		fogs[0].reveal_all()
	_update_fog()
	if ai_enabled:
		var ai := RtsAiPlayer.new()
		ai.name = "AI"
		ai.team = 1
		ai.level = ai_level
		add_child(ai)
	if bot_team == 0:
		var bot := RtsAiPlayer.new()
		bot.name = "Bot"
		bot.team = 0
		bot.level = 1
		bot.player_bot = true
		add_child(bot)
	for t in 2:
		income_multiplier[t] = 1.0
	income_multiplier[1] = float(RtsAiBrain.preset(ai_level).income_multiplier)


func _physics_process(delta: float) -> void:
	if winner >= 0:
		return
	elapsed += delta
	_alert_cool = maxf(_alert_cool - delta, 0.0)
	_fog_t -= delta
	if _fog_t <= 0.0:
		_fog_t = 1.0 / fog_rate
		_fog_team = 1 - _fog_team
		_update_fog(_fog_team)                   # one team a tick halves the spike
	if _rebake and not nav.is_baking():
		_rebake = false
		nav.bake_navigation_mesh(true)


func stockpile(t: int) -> RtsStockpile:
	return stockpiles[t]


func fog(t: int) -> RtsFog:
	return fogs[t]


# ---- the fog and what the player sees ----

## Recomputes the fog of team `only` (−1: both) and, with the player's, what the player sees.
func _update_fog(only: int = -1) -> void:
	for t in 2:
		if only >= 0 and t != only:
			continue
		var viewers: Array = []
		for u in units:
			if u.team == t:
				viewers.append({"at": u.global_position, "sight": float(u.def.sight)})
		for b in buildings:
			if b.team == t:
				viewers.append({"at": b.global_position, "sight": float(b.def.sight) * (1.0 if b.finished else 0.5)})
		fogs[t].update(viewers)
	if only == 1:
		return
	# The player's view: enemy units only in sight; enemy buildings once seen.
	var me := 0
	for u in units:
		if u.team != me:
			u.visible = fogs[me].is_visible(u.global_position)
	for b in buildings:
		if b.team != me:
			if fogs[me].is_visible(b.global_position):
				b.seen_by[me] = true
			b.visible = b.seen_by.has(me)
	# The terrain the player hasn't explored stays black: mines, trees and rocks appear once explored.
	for m in mines:
		m.visible = fogs[me].is_explored(m.global_position)
	for p in props:
		p.visible = fogs[me].is_explored(p.global_position)


func visible_to(t: int, node: Node3D) -> bool:
	return fogs[t].is_visible(node.global_position)


# ---- spawning and building ----

func spawn_unit(t: int, kind: StringName, at: Vector3) -> RtsUnit:
	var u := RtsUnit.new()
	u.name = "%s_%d_%d" % [kind, t, units.size()]
	u.position = Vector3(at.x, 0.05, at.z)
	world_root.add_child(u)
	u.setup(self, t, kind)
	units.append(u)
	stockpiles[t].supply_used += int(rules.unit(kind).supply) if not _reserved_spawn else 0
	return u


var _reserved_spawn := false


## A finished item leaves its building: at the edge nearest the rally point, then walks there (a worker sent to a mine
## starts gathering it).
func spawn_produced(b: RtsBuilding, kind: StringName) -> void:
	var rally := b.rally_point if b.rally_point != Vector3.INF else b.global_position + Vector3(0, 0, b.extent() + 2.0)
	var dir := (rally - b.global_position)
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.BACK
	_reserved_spawn = true                      # production already reserved its supply
	var u := spawn_unit(b.team, kind, b.global_position + dir * (b.extent() + 1.0))
	_reserved_spawn = false
	var mine := _mine_at(rally)
	if mine != null and u.is_worker():
		u.orders.give(RtsOrders.make(RtsOrders.Kind.GATHER, mine.global_position, mine))
	else:
		u.orders.give(RtsOrders.make(RtsOrders.Kind.MOVE, rally))


func place_building(t: int, kind: StringName, cell: Vector2i, done: bool) -> RtsBuilding:
	var def := rules.building(kind)
	var id := 1000 + buildings.size() + t * 100000 + randi() % 1000
	if not grid.place(cell, def.size, id):
		return null
	var b := RtsBuilding.new()
	b.name = "%s_%d_%d" % [kind, t, buildings.size()]
	b.position = grid.centre(cell, def.size)
	b.set_meta(&"grid_id", id)
	nav.add_child(b)                            # under the navigation region: its footprint is carved from the mesh
	b.setup(self, t, kind, cell, done)
	buildings.append(b)
	_clear_footprint(b)
	_rebake = true
	return b


## Units standing where a building goes up step out of its way (or they are walled in by its collision).
func _clear_footprint(b: RtsBuilding) -> void:
	for u in units:
		var p := u.global_position
		if b.edge_distance(p) > u.radius + 0.1:
			continue
		var hx := b.size.x * rules.cell_size * 0.5 + u.radius + 0.4
		var hz := b.size.y * rules.cell_size * 0.5 + u.radius + 0.4
		var d := p - b.global_position
		var out := Vector3(signf(d.x) * hx if absf(d.x) / hx > absf(d.z) / hz else d.x, 0.0, signf(d.z) * hz if absf(d.x) / hx <= absf(d.z) / hz else d.z)
		u.global_position = b.global_position + out + Vector3(0, 0.05, 0)


## Why team `t` can't put `kind` at `cell` ("" when it can): the grid's reasons (recipe 60), with the team's own fog.
func why_not_place(t: int, kind: StringName, cell: Vector2i) -> String:
	var saved := grid.explored
	grid.explored = func(c: Vector2i) -> bool: return fogs[t].is_explored(grid.centre(c, Vector2i.ONE))      # by world point: the grids' cells differ
	var why := grid.why_not(cell, rules.building(kind).size)
	grid.explored = saved
	return why


## A building order: checks the place and the cost, pays, puts the site down and sends the workers. Returns the site
## or null (the reason goes to `message` for the player).
func try_build(t: int, kind: StringName, cell: Vector2i, workers: Array, shift: bool = false) -> RtsBuilding:
	var why := why_not_place(t, kind, cell)
	if why != "":
		_say(t, {"outside": "Poza mapą", "occupied": "Tu coś stoi", "blocked": "Tu nie da się budować", "unexplored": "Nieodkryty teren"}.get(why, why))
		return null
	if not techs[t].available(kind):
		_say(t, "Wymaga: " + ", ".join(techs[t].missing(kind).map(func(k: StringName) -> String: return name_of(k))))
		return null
	if not stockpiles[t].spend(rules.building(kind).cost):
		_say(t, "Za mało surowców")
		return null
	var site := place_building(t, kind, cell, false)
	for w in workers:
		var u := w as RtsUnit
		if u != null and u.is_worker():
			u.orders.give(RtsOrders.make(RtsOrders.Kind.BUILD, site.global_position, site), shift)
	return site


## Queue a unit at a building (the command card). Returns whether it was queued.
func train(b: RtsBuilding, kind: StringName) -> bool:
	if not b.finished or not b.trains().has(kind):
		return false
	if not techs[b.team].available(kind):
		_say(b.team, "Wymaga: " + ", ".join(techs[b.team].missing(kind).map(func(k: StringName) -> String: return name_of(k))))
		return false
	var def := rules.unit(kind)
	if not b.production.enqueue(RtsProduction.item(kind, def.cost, int(def.supply), float(def.time))):
		_say(b.team, "Kolejka pełna" if b.production.queue.size() >= b.production.max_queue else "Za mało surowców")
		return false
	return true


func on_building_completed(b: RtsBuilding) -> void:
	stockpiles[b.team].provide(int(b.def.supply))
	techs[b.team].add(b.kind)
	if b.team == 0 and elapsed > 0.5:
		_say(0, "Ukończono: " + name_of(b.kind))


func on_building_died(b: RtsBuilding) -> void:
	grid.remove(int(b.get_meta(&"grid_id")))
	buildings.erase(b)
	if b.finished:
		stockpiles[b.team].provide(-int(b.def.supply))
		techs[b.team].remove(b.kind)
	if b.production.started and not b.production.queue.is_empty():
		stockpiles[b.team].release(int(b.production.queue[0].supply))      # the unit being made is lost with it
	_rebake = true
	_check_winner()


func on_unit_died(u: RtsUnit) -> void:
	units.erase(u)
	stockpiles[u.team].release(int(u.def.supply))


func on_mine_spent(m: RtsMine) -> void:
	mines.erase(m)
	for c in m.cells:
		grid.blocked.erase(c)


func on_deposit(t: int, res: StringName, n: int) -> void:
	var extra := roundi(n * (income_multiplier[t] - 1.0))
	if extra != 0:
		stockpiles[t].add(res, extra)


func on_supply_blocked(t: int) -> void:
	_say(t, "Za mało żywności — zbuduj farmę")


func _check_winner() -> void:
	var alive_teams := {}
	for b in buildings:
		if b.alive:
			alive_teams[b.team] = true
	if alive_teams.size() == 1:
		winner = alive_teams.keys()[0]
		game_over.emit(winner)
	elif alive_teams.is_empty():
		winner = 2
		game_over.emit(winner)


func _say(t: int, text: String) -> void:
	if t == 0:
		message.emit(text)


func name_of(kind: StringName) -> String:
	return {&"worker": "Robotnik", &"footman": "Piechur", &"archer": "Łucznik", &"rider": "Jeździec",
		&"town_hall": "Ratusz", &"farm": "Farma", &"barracks": "Koszary", &"stable": "Stajnia",
		&"gold": "Złoto", &"wood": "Drewno"}.get(kind, String(kind))


# ---- queries for units and the AI ----

## Everything a team owns of a kind, including what is being made (the AI's count).
func count(t: int, kind: StringName) -> int:
	var n := 0
	for u in units:
		if u.team == t and u.kind == kind:
			n += 1
	for b in buildings:
		if b.team == t:
			if b.kind == kind:
				n += 1
			for it in b.production.queue:
				if it.id == kind:
					n += 1
	return n


func pending(t: int, kind: StringName) -> int:
	var n := 0
	for b in buildings:
		if b.team == t:
			if b.kind == kind and not b.finished:
				n += 1
			for it in b.production.queue:
				if it.id == kind:
					n += 1
	return n


## The node a worker should go to: near, and with a free slot (a full one counts as 8 m further), never `busy`.
func nearest_resource(kind: StringName, from: Vector3, busy: RtsResourceNode = null) -> RtsResourceNode:
	var best: RtsMine = null
	var bd := INF
	for m in mines:
		if m.alive and m.kind == kind and not m.node.is_spent() and m.node != busy:
			var full := m.node.gathering.size() >= m.node.max_gatherers
			var d := m.global_position.distance_to(from) + (8.0 if full else 0.0)
			if d < bd:
				bd = d
				best = m
	return best.node if best != null else null


func mine_of(n: RtsResourceNode) -> RtsMine:
	for m in mines:
		if m.node == n:
			return m
	return null


func _mine_at(p: Vector3) -> RtsMine:
	for m in mines:
		if m.alive and m.global_position.distance_to(Vector3(p.x, m.global_position.y, p.z)) <= m.radius + 0.5:
			return m
	return null


func nearest_drop(t: int, from: Vector3) -> Vector3:
	var best := Vector3.INF
	for b in buildings:
		if b.team == t and b.finished and bool(b.def.drop_off):
			if best == Vector3.INF or from.distance_to(b.global_position) < from.distance_to(best):
				best = b.global_position
	return best


## Where a unit coming from `from` should walk to reach the mine or building centred at `at`: the point of its edge
## nearest to the unit, a step outside. (Walking to the centre makes the path end on whichever side the mesh picks.)
func approach_point(at: Vector3, from: Vector3, unit_radius: float) -> Vector3:
	for m in mines:
		if m.alive and Vector2(m.global_position.x, m.global_position.z).distance_to(Vector2(at.x, at.z)) < 0.1:
			var d := Vector3(from.x - at.x, 0.0, from.z - at.z)
			return at + (d.normalized() if d.length() > 0.01 else Vector3.BACK) * (m.radius + unit_radius + 0.25)
	for b in buildings:
		if Vector2(b.global_position.x, b.global_position.z).distance_to(Vector2(at.x, at.z)) < 0.1:
			var p := b.closest_point(from)
			var out := Vector3(from.x - p.x, 0.0, from.z - p.z)
			return p + (out.normalized() if out.length() > 0.01 else Vector3.BACK) * (unit_radius + 0.25)
	return at


## How far `from` is from the edge of the mine or building whose centre is `at` (a plain point: the distance to it).
func edge_distance_at(at: Vector3, from: Vector3) -> float:
	for m in mines:
		if m.alive and Vector2(m.global_position.x, m.global_position.z).distance_to(Vector2(at.x, at.z)) < 0.1:
			return m.edge_distance(from)
	for b in buildings:
		if Vector2(b.global_position.x, b.global_position.z).distance_to(Vector2(at.x, at.z)) < 0.1:
			return b.edge_distance(from)
	return Vector2(from.x - at.x, from.z - at.z).length()


## The target for a unit (recipe 63): enemies its team can see, inside `acquire`.
func pick_target(u: RtsUnit, acquire: float) -> Object:
	var c: Array = []
	for e in units:
		if e.team != u.team and e.alive and e.global_position.distance_to(u.global_position) <= acquire + 1.0:
			c.append({"node": e, "at": e.global_position, "attacking_me": u.attacking_me == e, "visible": fogs[u.team].is_visible(e.global_position)})
	for b in buildings:
		if b.team != u.team and b.alive and b.global_position.distance_to(u.global_position) <= acquire + b.extent() + 1.0:
			c.append({"node": b, "at": b.closest_point(u.global_position), "is_building": true, "visible": fogs[u.team].is_explored(b.global_position)})      # a building's range is to its walls
	return RtsCombat.pick_target(u.global_position, acquire, c, u.target)


## An archer's arrow: a short-lived line (one shared mesh and material, see godot-pitfalls).
var _arrow_mesh: BoxMesh


func shoot_arrow(from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.2:
		return
	if _arrow_mesh == null:
		_arrow_mesh = BoxMesh.new()
		_arrow_mesh.size = Vector3(0.03, 0.03, 1.0)
		_arrow_mesh.material = RtsLook.mat(Color(0.95, 0.9, 0.7), true)
	var m := MeshInstance3D.new()
	m.mesh = _arrow_mesh
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world_root.add_child(m)
	m.global_position = (from + to) * 0.5
	m.look_at_from_position(m.global_position, to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.RIGHT)
	m.scale = Vector3(1, 1, length)
	get_tree().create_timer(0.12).timeout.connect(m.queue_free)


## The player hears about attacks on their things (at most every 8 s).
func notify_attacked(t: int, at: Vector3) -> void:
	if t == 0 and _alert_cool <= 0.0:
		_alert_cool = 8.0
		alert.emit(at)
		message.emit("Jesteśmy atakowani!")
