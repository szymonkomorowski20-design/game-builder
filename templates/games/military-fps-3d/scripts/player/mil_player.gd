class_name MilPlayer
extends CharacterBody3D
## The player of a campaign mission (first person). Built on recipes:
##   53 GunModel per gun (rate, magazine, reloads, spread/bloom, ADS, recoil pattern, falloff);
##   54 Hitscan from the camera, with head / body / limb zones;
##   55 RegenHealth + DamageIndicators;
##   56 AimAssist (pads only).
## Yaw on this body, pitch on `Head`. The recoil is an offset on top of the aim (`GunModel.kick_accumulated`): the view
## climbs while firing and settles back when the trigger is released, and the player pulls down against it.
## Movement: walk, sprint (no firing, cancels a reload), crouch (toggle; the eye drops below low cover), jump.
## Observable: health, guns, gun_index, crouching, sprinting, aiming, shots_fired, hits, headshots, kills.

signal fired(from: Vector3, dir: Vector3, end: Vector3, hit: Dictionary)   ## every shot; hit is {} on a miss
signal hit_confirmed(kind: StringName)       ## &"body", &"head", &"limb" or &"kill" — the HUD's hit marker
signal hurt(amount: float, angle: float)     ## angle: where it came from, degrees, 0 = ahead, + = right
signal died
signal weapon_changed(index: int)

const WORLD := 1
const PLAYER := 2
const ENEMIES := 4
const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.2

@export var tuning: MilTuning
## Mouse look only while the mouse is captured (menus keep the cursor). Tests switch this off.
@export var require_captured_mouse := true

var yaw := 0.0
var pitch := 0.0
var guns: Array[GunModel] = []
var gun_index := 0
var health: RegenHealth
var indicators := DamageIndicators.new()
var assist := AimAssist.new()
var crouching := false
var sprinting := false
var aiming := false
var using_pad := false
var alive := true
var controls_enabled := true
## Set by an objective the player stands at: `action` goes to it, and `reload` (same pad button) is ignored there.
var interact_target: Node = null
var shots_fired := 0
var hits := 0
var headshots := 0
var kills := 0

var _eye := 1.6
var _since_sprint := INF
var _swap_left := 0.0
var _capsule: CapsuleShape3D

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera
@onready var view_model: Node3D = $Head/Camera/ViewModel
@onready var body_shape: CollisionShape3D = $Body


func _ready() -> void:
	health = RegenHealth.new(tuning.max_health)
	health.regen_delay = tuning.regen_delay
	health.regen_rate = tuning.regen_rate
	health.danger_below = tuning.danger_below
	health.died.connect(_on_died)
	for stats in [tuning.primary, tuning.secondary]:
		if stats != null:
			var g := GunModel.new(stats, 7 + guns.size())
			g.dry_fired.connect(_on_dry_fire)
			guns.append(g)
	_capsule = (body_shape.shape as CapsuleShape3D).duplicate()
	body_shape.shape = _capsule
	_eye = tuning.stand_eye
	camera.fov = tuning.fov
	look(0.0, 0.0)
	_update_view_model(0.0)


func gun() -> GunModel:
	return guns[gun_index]


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion == null or not controls_enabled or not alive:
		return
	if require_captured_mouse and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	using_pad = false
	var k := tuning.mouse_sensitivity * lerpf(1.0, tuning.ads_sensitivity_scale, gun().ads)
	look(-motion.screen_relative.x * k, -motion.screen_relative.y * k)


func _physics_process(delta: float) -> void:
	var t := tuning
	health.tick(delta)
	indicators.tick(delta)
	var can_act := controls_enabled and alive
	_look_stick(delta, can_act)

	# Stance: crouch toggles; sprinting needs forward input, no aiming, and stands you up.
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down") if can_act else Vector2.ZERO
	if can_act and Input.is_action_just_pressed("crouch"):
		crouching = not crouching
	aiming = can_act and Input.is_action_pressed("aim")
	var wants_sprint := can_act and Input.is_action_pressed("sprint") and input.y < -0.3 and not aiming
	if wants_sprint and not sprinting:
		gun().cancel_reload()
		crouching = false
	sprinting = wants_sprint
	_since_sprint = 0.0 if sprinting else _since_sprint + delta
	var eye_target := t.crouch_eye if crouching else t.stand_eye
	_eye = move_toward(_eye, eye_target, (t.stand_eye - t.crouch_eye) / maxf(t.crouch_time, 0.01) * delta)
	var height := CROUCH_HEIGHT if crouching else STAND_HEIGHT
	if not is_equal_approx(_capsule.height, height):
		_capsule.height = height
		body_shape.position.y = height * 0.5

	# Weapons.
	_swap_left = maxf(_swap_left - delta, 0.0)
	if can_act and Input.is_action_just_pressed("switch_weapon") and guns.size() > 1:
		gun().cancel_reload()
		gun_index = (gun_index + 1) % guns.size()
		_swap_left = t.swap_time
		weapon_changed.emit(gun_index)
	if can_act and Input.is_action_just_pressed("reload") and interact_target == null:
		gun().reload()
	var g := gun()
	g.set_ads(aiming and _swap_left <= 0.0)
	var ready_to_fire := _swap_left <= 0.0 and not sprinting and _since_sprint >= t.sprint_to_fire
	var trigger := can_act and ready_to_fire and Input.is_action_pressed("shoot")
	for shot in g.tick(delta, trigger):
		_fire(shot)
	if g.ammo == 0 and g.reserve > 0 and not g.is_reloading() and not sprinting and can_act:
		g.reload()      # an emptied magazine reloads by itself, as in the genre

	# Movement.
	var g_accel := JumpMath.gravity(t.jump_height, t.time_to_apex)
	if is_on_floor():
		if can_act and Input.is_action_just_pressed("jump") and not crouching:
			velocity.y = JumpMath.jump_velocity(t.jump_height, t.time_to_apex)
	else:
		velocity.y -= g_accel * delta
	var speed := t.crouch_speed if crouching else (t.sprint_speed if sprinting else t.walk_speed)
	speed *= lerpf(1.0, g.stats.ads_move_scale, g.ads)
	var dir := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw)
	var rate := t.acceleration if dir != Vector3.ZERO else t.friction
	if not is_on_floor():
		rate *= t.air_control
	var planar := Vector3(velocity.x, 0.0, velocity.z).move_toward(dir * speed, rate * delta)
	velocity.x = planar.x
	velocity.z = planar.z
	move_and_slide()

	camera.fov = lerpf(t.fov, t.fov * t.ads_fov_scale, g.ads)
	_apply_view()
	_update_view_model(delta)


func _look_stick(delta: float, can_act: bool) -> void:
	if not can_act:
		return
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick == Vector2.ZERO:
		return
	using_pad = true
	var k := tuning.stick_look_speed * lerpf(1.0, tuning.ads_sensitivity_scale, gun().ads) * delta
	var eye := camera.global_position
	var aim := -camera.global_transform.basis.z
	var targets: Array[Vector3] = []
	if tuning.aim_assist:
		targets = assist_targets()
	if not targets.is_empty():
		k *= assist.slowdown(eye, aim, targets)
	look(-stick.x * k, -stick.y * k)
	if not targets.is_empty():
		var p := assist.pull(eye, aim, camera.global_transform.basis, targets, stick, delta)
		look(-deg_to_rad(p.x), deg_to_rad(p.y))


## Chest points of living soldiers the player can see — what aim assist may pull toward (line of sight is ours).
func assist_targets() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var eye := camera.global_position
	var space := get_world_3d().direct_space_state
	for n in get_tree().get_nodes_in_group(&"soldiers"):
		var s := n as MilSoldier
		if s == null or not s.alive:
			continue
		var p := s.aim_point()
		var q := PhysicsRayQueryParameters3D.create(eye, p, WORLD)
		if space.intersect_ray(q).is_empty():
			out.append(p)
	return out


## Turn by d_yaw (left +) and d_pitch (up +) radians; pitch is clamped.
func look(d_yaw: float, d_pitch: float) -> void:
	yaw = wrapf(yaw + d_yaw, -PI, PI)
	pitch = clampf(pitch + d_pitch, deg_to_rad(tuning.min_pitch_deg), deg_to_rad(tuning.max_pitch_deg))
	_apply_view()


## Point the aim at a world position (tests, the bot, cut-scenes). The recoil offset stays on top.
func aim_at(point: Vector3) -> void:
	var from := global_position + Vector3(0, _eye, 0)
	var to := point - from
	yaw = atan2(-to.x, -to.z)
	pitch = clampf(atan2(to.y, Vector2(to.x, to.z).length()), deg_to_rad(tuning.min_pitch_deg), deg_to_rad(tuning.max_pitch_deg))
	_apply_view()


func eye_position() -> Vector3:
	return global_position + Vector3(0, _eye, 0)


## Where a soldier aims: the middle of the visible body (lower when crouched).
func aim_point() -> Vector3:
	return global_position + Vector3(0, _eye - 0.35, 0)


func _apply_view(minus_kick: Vector2 = Vector2.ZERO) -> void:
	if head == null:
		return
	var kick := (gun().kick_accumulated if not guns.is_empty() else Vector2.ZERO) - minus_kick
	rotation.y = yaw
	head.position.y = _eye
	head.rotation = Vector3(pitch + deg_to_rad(kick.y), -deg_to_rad(kick.x), 0.0)


func _fire(shot: GunModel.Shot) -> void:
	# This shot's own kick is already in kick_accumulated: it moves the view for the NEXT shot, so this one leaves
	# along the view as it was when the trigger released it.
	_apply_view(shot.kick)
	var g := gun()
	var from := camera.global_position
	var dir := Hitscan.shot_direction(camera.global_transform.basis, shot.offset)
	_apply_view()
	var hit := Hitscan.cast(get_world_3d(), from, dir, g.stats.max_range, WORLD | ENEMIES, [get_rid()])
	shots_fired += 1
	var end: Vector3 = from + dir * g.stats.max_range if hit.is_empty() else hit.position
	if not hit.is_empty() and hit.collider is MilSoldier:
		var target := hit.collider as MilSoldier
		var killed := target.take_shot(g.damage_at(hit.distance, hit.zone), hit.zone, global_position)
		hits += 1
		if hit.zone == &"head":
			headshots += 1
		if killed:
			kills += 1
		hit_confirmed.emit(&"kill" if killed else StringName(hit.zone))
	view_model.position.z += 0.05
	fired.emit(from, dir, end, hit)


func _on_dry_fire() -> void:
	gun().reload()   # an empty trigger pull starts the reload, as in the genre


## A soldier's bullet. `from` is where it was fired from (for the direction indicator).
func take_hit(amount: float, from: Vector3) -> void:
	if not alive:
		return
	health.take_damage(amount)
	var angle := RegenHealth.direction_to(camera.global_transform.basis, global_position, from)
	indicators.add(angle)
	hurt.emit(amount, angle)


func _on_died() -> void:
	alive = false
	gun().cancel_reload()
	died.emit()


## Back to life at a checkpoint: full health, magazines refilled, standing, facing `facing_yaw`.
func respawn(at: Vector3, facing_yaw: float = 0.0) -> void:
	global_position = at
	velocity = Vector3.ZERO
	yaw = facing_yaw
	pitch = 0.0
	crouching = false
	sprinting = false
	alive = true
	health = RegenHealth.new(tuning.max_health)
	health.regen_delay = tuning.regen_delay
	health.regen_rate = tuning.regen_rate
	health.danger_below = tuning.danger_below
	health.died.connect(_on_died)
	indicators = DamageIndicators.new()
	for g in guns:
		g.cancel_reload()
		g.ammo = g.stats.magazine
		g.reserve = maxi(g.reserve, g.stats.reserve)
		g.kick_accumulated = Vector2.ZERO
	_apply_view()


func _update_view_model(delta: float) -> void:
	var g := gun()
	var hip := Vector3(0.16, -0.15, -0.36)
	var ads_pos := Vector3(0.0, -0.105, -0.3)
	var target := hip.lerp(ads_pos, g.ads)
	if sprinting:
		target += Vector3(-0.05, -0.08, 0.05)
	if g.is_reloading() or _swap_left > 0.0:
		target += Vector3(0.0, -0.18, 0.0)
	view_model.position = view_model.position.lerp(target, clampf(delta * 14.0, 0.0, 1.0)) if delta > 0.0 else target
	for i in view_model.get_child_count():
		(view_model.get_child(i) as Node3D).visible = i == gun_index
