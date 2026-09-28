class_name RtsBuilding
extends StaticBody3D
## A building: a construction site until workers finish it (its hit points grow with the work), then it provides
## supply, unlocks the tech tree and trains units (recipe 60's RtsProduction). New units walk to the rally point.
## Destroyed: its cells free, its supply and tech go, and the navigation mesh is rebuilt.
## Observable: team, kind, finished, progress, hp, production, rally_point.

signal died(building: RtsBuilding)
signal completed(building: RtsBuilding)

var team := 0
var kind: StringName = &""
var is_building := true
var alive := true
var finished := false
var hp := 1.0
var max_hp := 1.0
var progress := 0.0                    ## seconds of work done
var build_time := 1.0
var size := Vector2i(2, 2)
var cell := Vector2i.ZERO
var def := {}
var game: RtsGame
var production: RtsProduction
var rally_point := Vector3.INF
var seen_by := {}                      ## team → true once that team has seen it (drawn in explored fog)

var _mesh: MeshInstance3D


func setup(g: RtsGame, t: int, k: StringName, at_cell: Vector2i, done: bool) -> void:
	game = g
	team = t
	kind = k
	def = g.rules.building(k)
	size = def.size
	cell = at_cell
	build_time = float(def.time)
	max_hp = float(def.hp)
	collision_layer = 1
	collision_mask = 0
	add_to_group(&"buildings")
	add_to_group(&"team_%d" % t)
	var w := size.x * g.rules.cell_size - 0.3
	var d := size.y * g.rules.cell_size - 0.3
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w, 2.5, d)
	shape.shape = box
	shape.position.y = 1.25
	add_child(shape)
	_mesh = RtsLook.building_body(k, Vector2(w, d), RtsLook.team_colour(t))
	add_child(_mesh)
	production = RtsProduction.new()
	production.stockpile = g.stockpile(t)
	production.produced.connect(_on_produced)
	production.blocked.connect(func(_id: StringName) -> void: g.on_supply_blocked(t))
	if done:
		progress = build_time
		hp = max_hp
		_finish()
	else:
		hp = max_hp * 0.1
		_update_look()


func extent() -> float:
	return size.x * game.rules.cell_size * 0.5


## How far `p` is from the building's walls (0 inside): what "next to it" means for builders, gatherers and attackers.
## Measured to the rectangle, not the centre, or a worker at a corner never counts as arrived.
## The point of the building's footprint nearest to `p` (what an attacker aims for and measures range to).
func closest_point(p: Vector3) -> Vector3:
	var hx := size.x * game.rules.cell_size * 0.5 - 0.15
	var hz := size.y * game.rules.cell_size * 0.5 - 0.15
	return Vector3(clampf(p.x, global_position.x - hx, global_position.x + hx), global_position.y, clampf(p.z, global_position.z - hz, global_position.z + hz))


func edge_distance(p: Vector3) -> float:
	var hx := size.x * game.rules.cell_size * 0.5 - 0.15
	var hz := size.y * game.rules.cell_size * 0.5 - 0.15
	var dx := maxf(absf(p.x - global_position.x) - hx, 0.0)
	var dz := maxf(absf(p.z - global_position.z) - hz, 0.0)
	return sqrt(dx * dx + dz * dz)


func armour() -> Dictionary:
	return {"armour": def.armour, "armour_type": def.armour_type, "tags": []}


func trains() -> Array:
	return def.get("trains", [])


## Work on the site (seconds of work); hit points grow with it.
func construct(work: float) -> void:
	if finished or not alive:
		return
	progress = minf(progress + work, build_time)
	hp = minf(hp + max_hp * 0.9 * work / build_time, max_hp)
	_update_look()
	if progress >= build_time:
		_finish()


func _finish() -> void:
	finished = true
	_update_look()
	game.on_building_completed(self)
	completed.emit(self)


func take_damage(amount: float, _by: Node3D) -> void:
	if not alive:
		return
	hp -= amount
	game.notify_attacked(team, global_position)
	if hp <= 0.0:
		alive = false
		game.on_building_died(self)
		died.emit(self)
		queue_free()


func _physics_process(delta: float) -> void:
	if finished and alive:
		production.tick(delta)


func _on_produced(id: StringName) -> void:
	game.spawn_produced(self, id)


func _update_look() -> void:
	var f := 1.0 if finished else clampf(progress / build_time, 0.15, 1.0)
	_mesh.scale = Vector3(1.0, f, 1.0)
	RtsLook.set_site(_mesh, not finished)
