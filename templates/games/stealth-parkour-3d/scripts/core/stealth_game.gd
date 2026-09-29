class_name StealthGame
extends Node3D
## The district's game (template stealth-parkour-3d). It builds the district (DistrictMap), bakes the navigation mesh,
## spawns the guards, the crowd and the target, and owns the shared systems:
## - `board` (recipe 69): what the guards know together;
## - `notoriety` and `wanted` (recipe 72): how known the player is, and the chase;
## - `viewpoints` and `contract` (recipe 73): the tower that reveals the district, and the one assassination contract;
## - `stage` (recipe 71): who may strike the player now;
## - `lanes` and `bench` (recipe 70): where the crowd walks and sits.
## Each physics frame it updates the crowd by distance bands, the target, the chase, the contract, and handles the
## player's actions: the strike, the action key (sync, tear a poster, hide), and the guards' strikes it resolves.

signal message(text: String)
signal contract_changed

const KILL_WITNESS_RADIUS := 14.0
const PANIC_RADIUS := 10.0
const FRIGHT_RADIUS := 18.0
const ESCAPE_DISTANCE := 20.0
const SEE_KILL_RADIUS := 25.0

var board := AlertBoard.new()
var notoriety := Notoriety.new()
var wanted := WantedSearch.new()
var viewpoints := ViewpointNetwork.new()
var contract := Contract.new(&"merchant")
var stage := MeleeStage.new()
var lanes: CrowdLanes
var bench: SmartSlots
var guards: Array[GuardAgent] = []
var civilians: Array[Civilian] = []
var target: TargetNpc
var world := {}
var clock := 0.0
var frame := 0
var noises := 0
var actions := 0
var target_body_at := Vector3.INF
var hidden_from: Callable
var seen_this_frame := false
## Tests only: the crowd stands still.
var crowd_frozen := false

@onready var nav: NavigationRegion3D = $Navigation
@onready var player: Assassin = $Player
@onready var camera_rig: OrbitCamera = $CameraRig
@onready var crowd_root: Node3D = $Crowd
@onready var guards_root: Node3D = $Guards


func _ready() -> void:
	hidden_from = _hidden_from
	board.alarm_radius = 30.0
	_navigation_mesh()
	world = DistrictMap.build(nav)
	nav.bake_navigation_mesh(false)
	lanes = DistrictMap.lanes()
	bench = SmartSlots.new(DistrictMap.bench_seats())
	player.teleport(DistrictMap.PLAYER_START)
	player.camera_path = player.get_path_to(camera_rig)
	player.noise_made.connect(_on_noise)
	player.struck.connect(_on_strike)
	player.died.connect(_on_player_died)
	camera_rig.target = player
	_spawn_guards()
	_spawn_crowd()
	target = TargetNpc.new()
	add_child(target)
	target.setup(self)
	target.reached_safety.connect(_on_target_safe)
	viewpoints.add_viewpoint(&"tower", DistrictMap.VIEWPOINT, DistrictMap.VIEWPOINT_RADIUS)
	viewpoints.add_marker(&"target_house", DistrictMap.DOOR, &"contract")
	for n: StringName in DistrictMap.POSTERS:
		viewpoints.add_marker(n, DistrictMap.POSTERS[n], &"poster")
	contract.start(0.0)
	if not _harness_active():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	clock += delta
	frame += 1
	seen_this_frame = false
	var cam := get_viewport().get_camera_3d()
	var eye := cam.global_position if cam != null else player.global_position
	for c in civilians:
		var d := c.position.distance_to(eye)
		if not crowd_frozen and CrowdRules.lod_due(frame, c.id, d):
			c.tick(delta * CrowdRules.lod_interval(d))
	target.tick(delta)
	player.blended = _crowd_blend()
	notoriety.tick(clock, delta)
	if Input.is_action_just_pressed(&"action"):
		_on_action()
	# The guards (children) report what they see after this; the chase reads last frame's sightings.
	wanted.tick(clock, player.global_position, player.is_hidden() or player.blended)
	_update_contract()


## The notoriety level's multiplier for how fast the guards notice.
func notice_scale() -> float:
	return float(notoriety.effect().notice)


## A hunting guard sees the player: the chase is on, and the contract's target is alerted.
func player_seen_by(_guard: GuardAgent) -> void:
	seen_this_frame = true
	wanted.seen(player.global_position, clock, notoriety.level())
	if contract.phase == Contract.Phase.APPROACH and not contract.target_alerted:
		contract.on_detected()
		target.alerted = contract.target_alerted
		message.emit("Cel cię zauważył — ucieka do pałacu!")
		contract_changed.emit()


func strike_started(_guard: GuardAgent, _strike: EnemyStrike) -> void:
	pass


## A guard's hit lands now: the player's defence answers it (recipe 71).
func resolve_strike(guard: GuardAgent, kind: int) -> void:
	match player.defense.resolve(kind, clock):
		CounterDefense.Result.HIT, CounterDefense.Result.GUARD_BROKEN:
			player.take_hit(1)
		CounterDefense.Result.COUNTERED:
			guard.take_hit(1, 0.8)
		CounterDefense.Result.PERFECT:
			guard.take_hit(2, 1.2)
	_stimulate_crowd(guard.global_position, CrowdMind.Mood.SCARED, 12.0)


func _on_strike() -> void:
	var fwd: Vector3 = -(player.get_node("Body") as Node3D).global_transform.basis.z
	var here := player.global_position
	if target.alive and _can_assassinate(target.global_position, fwd):
		target.kill()
		target_body_at = target.global_position
		_after_kill(target.global_position, true)
		return
	for g in guards:
		if g.alive and not g.is_hunting() and _can_assassinate(g.global_position, fwd):
			g.die()
			_after_kill(g.global_position, false)
			return
	var fighters: Array[Vector3] = []
	var who: Array[GuardAgent] = []
	for g in guards:
		if g.alive and g.global_position.distance_to(here) <= 3.0:
			fighters.append(g.global_position)
			who.append(g)
	var dir := player.wish_direction(player._input_vector())
	var i := MeleeTarget.pick(here, dir if dir != Vector3.ZERO else fwd, fighters, 2.5)
	if i >= 0:
		who[i].take_hit(1, 0.3)
		if not who[i].alive:
			_after_kill(who[i].global_position, false)


func _can_assassinate(at: Vector3, fwd: Vector3) -> bool:
	var to := at - player.global_position
	if absf(to.y) > 1.2:
		return false
	var flat := Vector3(to.x, 0.0, to.z)
	return flat.length() <= 1.6 and (flat.length() < 0.3 or flat.normalized().dot(fwd) > 0.2)


func _after_kill(at: Vector3, was_target: bool) -> void:
	contract.on_kill(was_target)
	if was_target:
		message.emit("Cel nie żyje. Uciekaj!")
	contract_changed.emit()
	for g in guards:
		if g.alive and g.senses.seen and g.global_position.distance_to(at) <= SEE_KILL_RADIUS:
			notoriety.witnessed(&"kill", true, clock)
			g.senses.meter.value = 1.0
			g.senses.meter.detected = true
	var reported := false
	for c in civilians:
		if c.position.distance_to(at) <= KILL_WITNESS_RADIUS and not reported:
			notoriety.witnessed(&"kill", false, clock)
			reported = true
	_stimulate_crowd(at, CrowdMind.Mood.PANIC, PANIC_RADIUS)
	_stimulate_crowd(at, CrowdMind.Mood.SCARED, FRIGHT_RADIUS)


func _stimulate_crowd(at: Vector3, mood: int, radius: float) -> void:
	for c in civilians:
		if c.position.distance_to(at) <= radius:
			c.mind.stimulate(mood, at, clock)


func _on_noise(at: Vector3, radius: float) -> void:
	noises += 1
	for g in guards:
		g.hear_noise(at, radius, "noise:%d" % noises)


func _on_action() -> void:
	actions += 1
	var here := player.global_position
	if here.distance_to(DistrictMap.VIEWPOINT) <= 2.5:
		var fresh := viewpoints.sync(&"tower")
		message.emit("Zsynchronizowano. Odkryte miejsca: %d" % fresh.size())
		return
	for n: StringName in world.posters:
		var poster := world.posters[n] as Node3D
		if is_instance_valid(poster) and poster.visible and here.distance_to(poster.global_position) <= 2.0:
			poster.visible = false
			poster.collision_layer = 0
			notoriety.tear_poster()
			message.emit("Zerwany list gończy (rozgłos −25)")
			return
	if player.is_hidden():
		player.hide_in(&"", here)
		return
	for hay: Node3D in world.soft:
		var box := (hay.get_child(0) as CollisionShape3D).shape as BoxShape3D
		var local := hay.to_local(here)
		if absf(local.x) <= box.size.x * 0.5 + 1.0 and absf(local.z) <= box.size.z * 0.5 + 1.0:
			var top := hay.global_position.y + box.size.y * 0.5
			player.hide_in(&"hay", Vector3(hay.global_position.x, top + 0.02, hay.global_position.z))
			return
	var seats := DistrictMap.bench_seats()
	if here.distance_to(seats[2]) <= 1.5 and bench.occupied() >= 2:
		player.hide_in(&"bench", seats[2])


func _crowd_blend() -> bool:
	var calm: Array[Vector3] = []
	for c in civilians:
		if c.is_calm():
			calm.append(c.position)
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	return CrowdRules.blended(player.global_position, speed, calm)


func _update_contract() -> void:
	if contract.phase == Contract.Phase.ESCAPE and not wanted.is_chased():
		if player.global_position.distance_to(target_body_at) >= ESCAPE_DISTANCE:
			contract.on_escaped(clock)
			message.emit("Kontrakt wykonany.")
			contract_changed.emit()


func _on_target_safe() -> void:
	contract.on_target_safe()
	message.emit("Cel schronił się w pałacu. Kontrakt nieudany.")
	contract_changed.emit()


func _on_player_died() -> void:
	contract.on_player_died()
	message.emit("Nie żyjesz.")
	contract_changed.emit()


func _spawn_guards() -> void:
	var scene := preload("res://scenes/npc/guard.tscn")
	for g: Array in DistrictMap.GUARDS:
		var guard := scene.instantiate() as GuardAgent
		guards_root.add_child(guard)
		var route: Array[Vector3] = []
		for p: Vector3 in g[3]:
			route.append(p)
		guard.setup(self, g[0], g[1], g[2], route, g[0] == &"door")
		guards.append(guard)


func _spawn_crowd() -> void:
	for i in DistrictMap.CROWD:
		var c := Civilian.new()
		crowd_root.add_child(c)
		c.setup(self, i, i % lanes.points.size())
		civilians.append(c)
	var seats := DistrictMap.bench_seats()
	for i in 2:
		var c := Civilian.new()
		crowd_root.add_child(c)
		c.setup(self, DistrictMap.CROWD + i, 0)
		var s := bench.reserve(c, seats[i])
		bench.occupy(c)
		c.sit(s, seats[s])
		civilians.append(c)


func _hidden_from(from: Vector3, point: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, point, 1)
	return not get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _navigation_mesh() -> void:
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.agent_radius = 0.5
	nm.agent_height = 1.75
	nm.agent_max_climb = 0.25
	nav.navigation_mesh = nm


func _harness_active() -> bool:
	var h := get_node_or_null("/root/GbHarness")
	return h != null and h.get(&"active") == true
