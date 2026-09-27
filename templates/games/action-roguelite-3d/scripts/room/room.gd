class_name RogueRoom
extends Node3D
## One combat room. The EncounterDirector (recipe 49) plans its waves from the room depth and seed; every enemy is
## announced by a glowing mark on the floor for `spawn_warning` seconds before it appears, so nothing materialises on
## top of the player. The boss room spawns the boss instead (its phase changes call adds). When the room is clear,
## `cleared` fires; the Run gives the reward, then calls show_doors() and waits for `door_chosen`.

signal cleared
signal door_chosen(door: RoomDoor)
signal enemy_killed

const RUSHER := preload("res://scenes/enemies/rusher.tscn")
const BRUTE := preload("res://scenes/enemies/brute.tscn")
const BOSS := preload("res://scenes/boss/boss.tscn")
const DOOR := preload("res://scenes/room/door.tscn")

@export var spawn_warning := 0.5
@export var attack_tokens := 2   ## melee enemies allowed to wind up or strike at the same time (fairness)

var director := EncounterDirector.new()
var tokens := AttackTokens.new()
var player: RoguePlayer
var boss: RogueBoss
var is_cleared := false
var _pending: Array[Dictionary] = []   # {scene, pos, left, mark}

@onready var start_point := $PlayerStart as Marker3D
@onready var _spawns := $Spawns
@onready var _sockets := $DoorSockets
@onready var _enemies := $Enemies


func begin(p: RoguePlayer, depth: int, seed: int, boss_room: bool) -> void:
	player = p
	if boss_room:
		_spawn_boss()
		return
	director.kinds = [_kind(&"rusher", 1, 0, RUSHER), _kind(&"brute", 3, 1, BRUTE)]
	director.base_budget = 3.0
	director.budget_per_depth = 1.5
	director.depth_per_extra_wave = 2
	director.max_waves = 3
	director.wave_delay = 0.8
	director.wave_started.connect(_on_wave)
	director.cleared.connect(_on_cleared)
	director.start(depth, seed)


func alive_enemies() -> Array[Node]:
	return _enemies.get_children().filter(func(n: Node) -> bool: return not n.is_queued_for_deletion())


func show_doors(doors: Array[RoomDoor]) -> void:
	var sockets := _sockets.get_children()
	var first := (sockets.size() - doors.size()) / 2
	for i in doors.size():
		var door := DOOR.instantiate() as RogueDoor
		add_child(door)
		door.global_position = (sockets[first + i] as Marker3D).global_position
		door.setup(doors[i])
		door.entered.connect(func() -> void: door_chosen.emit(doors[i]))


func _physics_process(delta: float) -> void:
	director.tick(delta)
	for p in _pending.duplicate():
		p.left -= delta
		if p.left <= 0.0:
			_pending.erase(p)
			(p.mark as Node).queue_free()
			_spawn_now(p.scene, p.pos)


func _on_wave(_index: int, ids: Array) -> void:
	var points := _spawns.get_children()
	for i in ids.size():
		var pos := (points[i % points.size()] as Marker3D).global_position
		pos += Vector3(0.6 * (i / points.size()), 0, 0)
		_announce(director.kind(ids[i]).scene, pos)


func _announce(scene: PackedScene, pos: Vector3) -> void:
	var mark := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.6
	disc.bottom_radius = 0.6
	disc.height = 0.02
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2)
	disc.material = mat
	mark.mesh = disc
	add_child(mark)
	mark.global_position = pos + Vector3(0, 0.02, 0)
	_pending.append({"scene": scene, "pos": pos, "left": spawn_warning, "mark": mark})


func _spawn_now(scene: PackedScene, pos: Vector3) -> RogueEnemy:
	var e := scene.instantiate() as RogueEnemy
	e.target = player
	tokens.limit = attack_tokens
	e.tokens = tokens
	_enemies.add_child(e)
	e.global_position = pos
	e.died.connect(_on_enemy_died)
	return e


func _on_enemy_died(_e: RogueEnemy) -> void:
	enemy_killed.emit()
	if boss == null:
		director.enemy_died()


func _on_cleared() -> void:
	is_cleared = true
	cleared.emit()


func _spawn_boss() -> void:
	boss = BOSS.instantiate() as RogueBoss
	boss.target = player
	add_child(boss)
	boss.global_position = Vector3(0, 0, -2)
	boss.adds_requested.connect(func(count: int) -> void:
		var points := _spawns.get_children()
		for i in count:
			_announce(RUSHER, (points[i] as Marker3D).global_position))
	boss.defeated.connect(func() -> void:
		for e in alive_enemies():
			e.queue_free()
		boss.queue_free()
		_on_cleared())


static func _kind(id: StringName, cost: int, min_depth: int, scene: PackedScene) -> EnemyKind:
	var k := EnemyKind.new()
	k.id = id
	k.cost = cost
	k.min_depth = min_depth
	k.scene = scene
	return k
