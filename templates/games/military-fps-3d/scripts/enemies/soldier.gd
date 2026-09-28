class_name MilSoldier
extends CharacterBody3D
## An enemy soldier: the body for recipe 57's ShooterBrain (decisions) and CoverFinder (where to hide).
## Each tick it feeds the brain three facts: arrived at the cover target, sees the player (from standing eye height),
## the player moved. It does what the brain's state says:
##   MOVE / FLANK — walk the navigation path to `brain.cover_target`;
##   COVER / RELOAD — crouch behind it (the collision shapes shrink, so low cover really stops bullets);
##   PEEK — stand, face the player, fire bursts; each round hits with `brain.accuracy(difficulty)`, so the first
##          shots at a player who just appeared mostly miss (a miss draws a tracer past the player).
## At most N soldiers peek at once (AttackTokens, recipe 49, owned by the mission). Barks tell the player what it's
## doing. Hits: `take_shot()` from the player's hitscan (zones head / body from the shapes' `hit_zone` meta).

signal died(soldier: MilSoldier)
signal barked(soldier: MilSoldier, kind: StringName)
signal shot_fired(from: Vector3, to: Vector3, hit_player: bool)

const WORLD := 1
const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.1
const STAND_EYE := 1.6
const BODY_STANDING := 1.4        ## capsule height (radius 0.38); the head sphere sits above it
const BODY_CROUCHED := 0.76
const HEAD_STANDING := 1.6
const HEAD_CROUCHED := 0.9
const STUCK_AFTER := 2.0          ## s without progress on a path → treat as arrived (never soft-lock)

@export var tuning: SoldierTuning
## Tests: stands where it is, never moves or fires (a target for aim and damage checks).
@export var passive := false

var brain := ShooterBrain.new()
var finder := CoverFinder.new()
var health := 100.0
var alive := true
var difficulty := 1.0
var player: MilPlayer
var cover_points: Array[Vector3] = []
## () -> Array[Vector3]: cover targets other soldiers already hold (the mission knows).
var occupied := func() -> Array[Vector3]: return []
var rng := RandomNumberGenerator.new()
var shots := 0
var hits_on_player := 0
var last_accuracy := -1.0      ## the hit chance the last shot used (tests: a peek starts at accuracy_min)

var _sees := false
var _saw_once := false
var _sight_timer := 0.0
var _last_player_pos := Vector3.INF
var _player_moved := false
var _burst_left := 0
var _shot_cooldown := 0.0
var _recheck := 1.0
var _stuck := 0.0
var _last_dist := INF
var _crouched := false
var _body_capsule: CapsuleShape3D

@onready var agent: NavigationAgent3D = $Agent
@onready var body_shape: CollisionShape3D = $Body
@onready var head_shape: CollisionShape3D = $Head
@onready var model: Node3D = $Model
@onready var flash: OmniLight3D = $Model/Gun/Flash


func _ready() -> void:
	health = tuning.max_health
	_body_capsule = (body_shape.shape as CapsuleShape3D).duplicate()
	body_shape.shape = _body_capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tuning.color
	($Model/Torso as MeshInstance3D).material_override = mat
	add_to_group(&"soldiers")


## Freed while alive (the zone reset after the player died): hand the shoot token back, or nobody could peek again.
func _exit_tree() -> void:
	if brain.tokens != null:
		brain.tokens.give_back(brain)


## Called by the encounter zone right after spawning.
func setup(p: MilPlayer, covers: Array[Vector3], tokens: AttackTokens, occupied_fn: Callable, difficulty_scale: float, seed_value: int, in_cover: bool = false) -> void:
	player = p
	cover_points = covers
	occupied = occupied_fn
	difficulty = difficulty_scale
	rng.seed = seed_value
	var t := tuning
	brain.tokens = tokens
	brain.peek_wait = t.peek_wait
	brain.peek_time = t.peek_time
	brain.reload_time = t.reload_time
	brain.magazine = t.magazine
	brain.rounds = t.magazine
	brain.aim_time = t.aim_time
	brain.accuracy_min = t.accuracy_min
	brain.accuracy_max = t.accuracy_max
	brain.flank_after = t.flank_after
	finder.near = t.near
	finder.far = t.far
	brain.state_changed.connect(_on_state)
	brain.bark.connect(func(kind: StringName) -> void: barked.emit(self, kind))
	if in_cover:
		brain.move_to(global_position)    # already there: the first tick arrives, crouched
		set_crouched(true)
	else:
		_pick_cover()


func aim_point() -> Vector3:
	return global_position + Vector3(0, 0.7 if _crouched else 1.2, 0)


func head_point() -> Vector3:
	return global_position + Vector3(0, head_shape.position.y, 0)


func eye_position() -> Vector3:
	return global_position + Vector3(0, STAND_EYE, 0)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	if not alive or passive or player == null:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	_sense(delta)
	var arrived := _walk(delta)
	brain.tick(delta, arrived, _sees, _player_moved)
	_player_moved = false
	if brain.state == ShooterBrain.Mode.PEEK:
		_face(player.global_position)
		_shoot(delta)
	else:
		_burst_left = 0
		_shot_cooldown = maxf(_shot_cooldown - delta, 0.0)
		if brain.state == ShooterBrain.Mode.COVER or brain.state == ShooterBrain.Mode.RELOAD:
			_face(player.global_position)
	# The player may walk around our cover: if it no longer hides us, find another (every second).
	_recheck -= delta
	if _recheck <= 0.0:
		_recheck = 1.0
		if (brain.state == ShooterBrain.Mode.COVER or brain.state == ShooterBrain.Mode.RELOAD) and not cover_points.is_empty():
			if not finder.is_useful(get_world_3d().direct_space_state, brain.cover_target, player.eye_position()):
				_pick_cover()
	set_crouched(brain.state == ShooterBrain.Mode.COVER or brain.state == ShooterBrain.Mode.RELOAD)
	flash.visible = _shot_cooldown > 60.0 / tuning.rpm * 0.6 and brain.state == ShooterBrain.Mode.PEEK


func _sense(delta: float) -> void:
	if _last_player_pos == Vector3.INF or player.global_position.distance_to(_last_player_pos) > 1.5:
		_last_player_pos = player.global_position
		_player_moved = true
	_sight_timer -= delta
	if _sight_timer > 0.0:
		return
	_sight_timer = 0.1
	var eye := eye_position()
	var target := player.aim_point()
	_sees = player.alive and eye.distance_to(target) <= tuning.sight_range
	if _sees:
		var q := PhysicsRayQueryParameters3D.create(eye, target, WORLD)
		_sees = get_world_3d().direct_space_state.intersect_ray(q).is_empty()
	if _sees and not _saw_once:
		_saw_once = true
		barked.emit(self, &"contact")


## Moves along the path while the brain says MOVE / FLANK. Returns true on arrival.
func _walk(delta: float) -> bool:
	var moving := brain.state == ShooterBrain.Mode.MOVE or brain.state == ShooterBrain.Mode.FLANK
	if not moving:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return false
	var to := brain.cover_target - global_position
	to.y = 0.0
	var dist := to.length()
	if dist < 0.45:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return true
	if dist < _last_dist - 0.05:
		_last_dist = dist
		_stuck = 0.0
	else:
		_stuck += delta
		if _stuck > STUCK_AFTER:
			_stuck = 0.0
			_last_dist = INF
			brain.cover_target = global_position    # hold here: an unreachable point must not freeze the fight
			return true
	if agent.target_position.distance_to(brain.cover_target) > 0.3:
		agent.target_position = brain.cover_target
	var next := brain.cover_target
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) > 0 and not agent.is_navigation_finished():
		next = agent.get_next_path_position()
	var d := next - global_position
	d.y = 0.0
	var v := d.normalized() * tuning.move_speed if d.length() > 0.01 else Vector3.ZERO
	velocity.x = v.x
	velocity.z = v.z
	if v != Vector3.ZERO:
		_face(global_position + v)
	move_and_slide()
	return false


func _shoot(delta: float) -> void:
	_shot_cooldown -= delta
	if _shot_cooldown > 0.0 or not _sees or not player.alive:
		return
	if _burst_left <= 0:
		_burst_left = rng.randi_range(tuning.burst_min, tuning.burst_max)
	var accuracy := brain.accuracy(difficulty)
	if not brain.fire_round():
		return
	last_accuracy = accuracy
	_burst_left -= 1
	_shot_cooldown = 60.0 / tuning.rpm + (tuning.burst_pause if _burst_left <= 0 else 0.0)
	shots += 1
	var from := global_position + Vector3(0, 1.45, 0) + (-global_transform.basis.z) * 0.6
	var hit := rng.randf() < accuracy
	var to := player.aim_point()
	if hit:
		hits_on_player += 1
		player.take_hit(tuning.damage, eye_position())
	else:
		# A miss that reads as a miss: past the player's head or shoulder, never through the body.
		var side := (to - from).cross(Vector3.UP).normalized()
		var off := side * rng.randf_range(0.6, 1.4) * (1.0 if rng.randf() < 0.5 else -1.0) + Vector3.UP * rng.randf_range(0.2, 0.8)
		to = to + off
	shot_fired.emit(from, to, hit)


## A hit from the player. Returns true when it killed.
func take_shot(amount: float, _zone: StringName, _from: Vector3) -> bool:
	if not alive:
		return false
	health -= amount
	brain.suppress()
	_flash_hit()
	if health <= 0.0:
		_die()
		return true
	return false


## Bullets landing close: back into cover (the mission calls this for shots near us).
func suppress() -> void:
	if alive:
		brain.suppress()


func _die() -> void:
	alive = false
	if brain.tokens != null:
		brain.tokens.give_back(brain)
	remove_from_group(&"soldiers")
	collision_layer = 0
	collision_mask = WORLD
	flash.visible = false
	var tw := create_tween()
	tw.tween_property(model, "rotation:x", -PI * 0.5, 0.35).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(model, "position:y", 0.25, 0.35)
	died.emit(self)
	get_tree().create_timer(6.0).timeout.connect(queue_free)


func _on_state(state: ShooterBrain.Mode) -> void:
	if state == ShooterBrain.Mode.FLANK:
		_pick_cover(brain.cover_target)


## Chooses a cover point (useful against the player right now, free, in the distance band) and walks there.
## With `flank_from`, it prefers a new angle on the player. No useful point: hold the current position.
func _pick_cover(flank_from: Variant = null) -> void:
	_last_dist = INF
	_stuck = 0.0
	var best: Variant = null
	if not cover_points.is_empty():
		var taken: Array[Vector3] = occupied.call()
		best = finder.best(get_world_3d().direct_space_state, cover_points, global_position, player.eye_position(), taken, flank_from)
	brain.move_to(best if best != null else global_position)


## Crouch (in cover) or stand. Public for tests; the soldier calls it every tick from its brain state.
func set_crouched(on: bool) -> void:
	if on == _crouched:
		return
	_crouched = on
	# The head sphere (r 0.2) sits on top of the body capsule, never inside it, or headshots would hit the body.
	# Crouched, everything stays under low cover (1.1 m): body 0–0.76 m, head 0.7–1.1 m.
	var body_h := BODY_CROUCHED if on else BODY_STANDING
	_body_capsule.height = body_h
	body_shape.position.y = body_h * 0.5
	head_shape.position.y = HEAD_CROUCHED if on else HEAD_STANDING
	model.scale.y = (CROUCH_HEIGHT if on else STAND_HEIGHT) / STAND_HEIGHT


func _face(point: Vector3) -> void:
	var d := point - global_position
	d.y = 0.0
	if d.length() > 0.05:
		rotation.y = atan2(-d.x, -d.z)


func _flash_hit() -> void:
	var torso := $Model/Torso as MeshInstance3D
	var mat := torso.material_override as StandardMaterial3D
	if mat == null:
		return
	mat.emission_enabled = true
	mat.emission = Color(1, 0.9, 0.7)
	mat.emission_energy_multiplier = 1.5
	get_tree().create_timer(0.06).timeout.connect(func() -> void:
		if is_instance_valid(torso):
			mat.emission_enabled = false)
