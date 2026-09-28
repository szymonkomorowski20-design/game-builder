class_name MilMission
extends Node3D
## One campaign mission, start to extraction (main scene). It owns the flow:
##   GATE → COURTYARD (zone 1) → TO_WAREHOUSE → WAREHOUSE (zone 2) → RADIO (hold `action`) → REINFORCEMENTS
##   (zone 3, started by the radio) → EXTRACT (walk onto the pad) → COMPLETE.
## The objective line always says what to do next (genre doc §4: the player always knows the objective).
## It also owns what several parts share:
##   - the navigation mesh, baked at start from the level's static colliders;
##   - AttackTokens (at most `attack_tokens` soldiers peek and fire at once, recipe 49);
##   - CheckpointTracker (recipe 41, furthest wins);
##   - fair spawns (SpawnPicker);
##   - tracers, suppression of soldiers near the player's impacts, death and respawn at the checkpoint.
## Observable: stage, deaths, elapsed, unfair_spawns, soldier_shots, soldier_hits, player, hud.

signal stage_changed(stage: Stage)

enum Stage { GATE, COURTYARD, TO_WAREHOUSE, WAREHOUSE, RADIO, REINFORCEMENTS, EXTRACT, COMPLETE }

const OBJECTIVES := {
	Stage.GATE: "Przejdź przez bramę na dziedziniec",
	Stage.COURTYARD: "Oczyść dziedziniec",
	Stage.TO_WAREHOUSE: "Wejdź do magazynu",
	Stage.WAREHOUSE: "Oczyść magazyn",
	Stage.RADIO: "Zniszcz radiostację (przytrzymaj E)",
	Stage.REINFORCEMENTS: "Odeprzyj posiłki",
	Stage.EXTRACT: "Dotrzyj do punktu ewakuacji",
	Stage.COMPLETE: "Misja wykonana",
}

@export var soldier_scene: PackedScene
@export var difficulty := 1.0                ## × soldier accuracy: 0.7 easy · 1.0 normal · 1.3 hard
@export var attack_tokens := 2               ## soldiers peeking and firing at once
@export var respawn_delay := 2.5             ## s of the death screen before the checkpoint
@export var reinforcements_delay := 2.0      ## s after a respawn in the reinforcements fight before it restarts
@export var mission_seed := 1

var stage := Stage.GATE
var tokens := AttackTokens.new()
var checkpoints: CheckpointTracker
var picker := SpawnPicker.new()
var deaths := 0
var elapsed := 0.0
var unfair_spawns := 0
var unfair_log: Array[String] = []     ## where the player stood when a wave had to spawn unfairly (level design)
var soldiers_spawned := 0
var soldier_shots := 0
var soldier_hits := 0

var _dead_for := -1.0
var _restart_zone_in := -1.0
var _tracer_mesh: BoxMesh                     ## one unit-long box for every tracer, stretched per shot
var _tracer_materials := {}                  ## colour → its material, made once

@onready var player: MilPlayer = $Player
@onready var hud: MilHud = $HUD
@onready var level: NavigationRegion3D = $Level
@onready var courtyard: EncounterZone = $Zones/Courtyard
@onready var warehouse: EncounterZone = $Zones/Warehouse
@onready var extraction: EncounterZone = $Zones/Extraction
@onready var radio: MilObjective = $Radio
@onready var pad: Area3D = $ExtractionPad
@onready var soldiers_root: Node3D = $Soldiers
@onready var effects: Node3D = $Effects


func _ready() -> void:
	tokens.limit = attack_tokens
	checkpoints = CheckpointTracker.new(player.global_position)
	level.bake_navigation_mesh(false)
	for z in [courtyard, warehouse, extraction]:
		(z as EncounterZone).mission = self
	extraction.trigger_on_enter = false
	courtyard.started.connect(func(z: EncounterZone) -> void: _zone_started(z, Stage.COURTYARD))
	courtyard.cleared.connect(func(_z: EncounterZone) -> void: _advance(Stage.COURTYARD, Stage.TO_WAREHOUSE))
	warehouse.started.connect(func(z: EncounterZone) -> void: _zone_started(z, Stage.WAREHOUSE))
	warehouse.cleared.connect(func(_z: EncounterZone) -> void:
		if _advance(Stage.WAREHOUSE, Stage.RADIO):
			radio.enabled = true)
	radio.completed.connect(_on_radio_done)
	extraction.started.connect(func(z: EncounterZone) -> void: _zone_started(z, Stage.REINFORCEMENTS))
	extraction.cleared.connect(func(_z: EncounterZone) -> void: _advance(Stage.REINFORCEMENTS, Stage.EXTRACT))
	pad.body_entered.connect(func(b: Node3D) -> void:
		if b == player and stage == Stage.EXTRACT and player.alive:
			_complete())
	player.fired.connect(_on_player_fired)
	player.died.connect(_on_player_died)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_set_stage(Stage.GATE)


func objective_text() -> String:
	return OBJECTIVES[stage]


func current_zone() -> EncounterZone:
	match stage:
		Stage.COURTYARD:
			return courtyard
		Stage.WAREHOUSE:
			return warehouse
		Stage.REINFORCEMENTS:
			return extraction
	return null


func enemies_left() -> int:
	var z := current_zone()
	if z == null:
		return 0
	var later := 0
	for i in range(z.wave + 1, z.waves.size()):
		later += z.waves[i]
	return z.alive.size() + later


func _physics_process(delta: float) -> void:
	if stage != Stage.COMPLETE:
		elapsed += delta
	if _dead_for >= 0.0:
		_dead_for += delta
		if _dead_for >= respawn_delay:
			_dead_for = -1.0
			_respawn()
	if _restart_zone_in >= 0.0:
		_restart_zone_in -= delta
		if _restart_zone_in <= 0.0:
			_restart_zone_in = -1.0
			extraction.start()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if captured else Input.MOUSE_MODE_CAPTURED
	elif stage == Stage.COMPLETE and event.is_action_pressed("action"):
		get_tree().reload_current_scene()


## Spawns `count` soldiers of `zone` at fair points and returns them. A dug-in wave starts crouched at cover points
## that hide it from the player right now; a later wave runs in from the zone's hidden spawn points.
## Returns [] (nothing spawned) when there are not enough fair points and `force` is off: the zone waits and asks
## again, so a wave never appears in plain view or behind the player just because they pushed deep.
func spawn_wave(zone: EncounterZone, count: int, force: bool = false) -> Array[MilSoldier]:
	var out: Array[MilSoldier] = []
	var space := get_world_3d().direct_space_state
	var dug_in := zone.wave < zone.dug_in_waves
	var points: Array[Vector3]
	if dug_in:
		var finder := CoverFinder.new()
		var useful: Array[Vector3] = []
		for c in zone.cover_points():
			if finder.is_useful(space, c, player.eye_position()):
				useful.append(c)
		points = picker.pick(space, useful, player.eye_position(), zone.ahead(), count, CoverFinder.CROUCH)
		var missing := picker.last_unfair
		points = points.slice(0, count - missing)
		if missing > 0:     # not enough hidden cover: the rest run in from the spawn points
			points.append_array(picker.pick(space, zone.spawn_points(), player.eye_position(), zone.ahead(), missing))
	else:
		points = picker.pick(space, zone.spawn_points(), player.eye_position(), zone.ahead(), count)
	if picker.last_unfair > 0 and not force:
		return out
	unfair_spawns += picker.last_unfair
	if picker.last_unfair > 0:
		unfair_log.append("%s wave %d: player at (%.0f, %.0f)" % [zone.title, zone.wave, player.global_position.x, player.global_position.z])
	if points.is_empty():
		points.append(zone.global_position)
	for i in count:
		var s := soldier_scene.instantiate() as MilSoldier
		var p: Vector3 = points[i % points.size()] + Vector3(floorf(float(i) / points.size()) * 0.9, 0.0, 0.0)
		s.position = p
		soldiers_root.add_child(s)
		soldiers_spawned += 1
		s.setup(player, zone.cover_points(), tokens, _occupied_covers, difficulty, mission_seed * 1000 + soldiers_spawned, dug_in)
		s.barked.connect(hud.show_bark)
		s.shot_fired.connect(_on_soldier_fired)
		s.died.connect(_on_soldier_died)
		out.append(s)
	return out


## Cover targets held by living soldiers (so two don't pick the same crate).
func _occupied_covers() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for n in get_tree().get_nodes_in_group(&"soldiers"):
		var s := n as MilSoldier
		if s != null and s.alive:
			out.append(s.brain.cover_target)
	return out


## A zone may start only when the mission expects it, so the stages advance in order: never skipped, never
## repeated. A player who runs past an unfinished arena into the next one starts nothing there; that arena starts
## by itself once it is its turn (the zone keeps checking whether the player stands in it).
func can_start(zone: EncounterZone) -> bool:
	if zone == courtyard:
		return stage == Stage.GATE
	if zone == warehouse:
		return stage == Stage.TO_WAREHOUSE
	if zone == extraction:
		return (stage == Stage.RADIO and radio.done) or (stage == Stage.REINFORCEMENTS and not zone.active)
	return false


## Moves from `from` to `to` only if the mission is at `from` (a late signal can never take the objective back).
func _advance(from: Stage, to: Stage) -> bool:
	if stage != from:
		return false
	_set_stage(to)
	return true


func _zone_started(zone: EncounterZone, next: Stage) -> void:
	checkpoints.reach(zone.order, zone.checkpoint_position())
	_set_stage(next)


func _on_radio_done() -> void:
	checkpoints.reach(extraction.order, extraction.checkpoint_position())
	hud.show_banner("Ładunek podłożony — posiłki nadchodzą!")
	extraction.start()


func _set_stage(s: Stage) -> void:
	stage = s
	stage_changed.emit(s)


func _complete() -> void:
	_set_stage(Stage.COMPLETE)
	player.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_complete()


## Tracer, and suppression: a soldier the bullet passed within suppress_radius of (the whizz, not only the impact).
func _on_player_fired(from: Vector3, _dir: Vector3, end: Vector3, _hit: Dictionary) -> void:
	var muzzle := player.view_model.global_position + (-player.camera.global_transform.basis.z) * 0.35
	spawn_tracer(muzzle, end, Color(1.0, 0.85, 0.45))
	for n in get_tree().get_nodes_in_group(&"soldiers"):
		var s := n as MilSoldier
		if s == null or not s.alive:
			continue
		var c := Geometry3D.get_closest_point_to_segment(s.aim_point(), from, end)
		if c.distance_to(s.aim_point()) <= player.tuning.suppress_radius:
			s.suppress()


func _on_soldier_fired(from: Vector3, to: Vector3, hit_player: bool) -> void:
	soldier_shots += 1
	var end := to
	if hit_player:
		soldier_hits += 1
		end = to - (to - from).normalized() * minf(1.5, from.distance_to(to) * 0.5)   # stops short of the camera
	spawn_tracer(from, end, Color(1.0, 0.55, 0.3))


func _on_soldier_died(s: MilSoldier) -> void:
	for n in get_tree().get_nodes_in_group(&"soldiers"):
		var other := n as MilSoldier
		if other != null and other.alive and other.global_position.distance_to(s.global_position) < 15.0:
			hud.show_bark(other, &"man_down")
			break


## A bright line from → to for 0.06 s: every shot's path is visible (genre doc §1, tracers).
func spawn_tracer(from: Vector3, to: Vector3, color: Color) -> void:
	var length := from.distance_to(to)
	if length < 0.1:
		return
	# One mesh and one material per colour, shared: a new material per shot cost a ~6 ms physics step every second in
	# a busy fight (measured in the proof game "Operacja Pył").
	if _tracer_mesh == null:
		_tracer_mesh = BoxMesh.new()
		_tracer_mesh.size = Vector3(0.012, 0.012, 1.0)
	var mat: StandardMaterial3D = _tracer_materials.get(color)
	if mat == null:
		mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		_tracer_materials[color] = mat
	var m := MeshInstance3D.new()
	m.mesh = _tracer_mesh
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effects.add_child(m)
	m.global_position = (from + to) * 0.5
	m.look_at_from_position(m.global_position, to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.RIGHT)
	m.scale = Vector3(1.0, 1.0, length)
	get_tree().create_timer(0.06).timeout.connect(m.queue_free)


func _on_player_died() -> void:
	deaths += 1
	_dead_for = 0.0
	player.controls_enabled = false
	hud.show_death()


func _respawn() -> void:
	var zone := current_zone()
	if zone != null:
		zone.reset()
	match stage:
		Stage.COURTYARD:
			_set_stage(Stage.GATE)
		Stage.WAREHOUSE:
			_set_stage(Stage.TO_WAREHOUSE)
		Stage.REINFORCEMENTS:
			_restart_zone_in = reinforcements_delay
	player.respawn(checkpoints.respawn_position, 0.0)
	player.controls_enabled = true
	hud.hide_death()
