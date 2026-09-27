class_name RogueBoss
extends CharacterBody3D
## The area boss, driven by BossBrain (recipe 51): phases at 66% / 33% (a big hit stops at the threshold, the change is
## invulnerable and calls two adds), attacks telegraph → strike → recovery. Every telegraph has two cues: a red disc
## on the ground showing exactly where it will hurt, and the body turning bright. Moves:
##   slam   — around the boss (radius slam_radius)
##   lunge  — charges at where the player stood when the strike starts; hurts on contact. Telegraph: a lane on the
##            ground from the boss toward the player. It follows the player until `lunge_lock` of the telegraph,
##            then freezes — the charge is committed, so a late sidestep works
##   nova   — (phase 1+) a wide ring (radius nova_radius): get out or dash through at the right moment
## The player's hits go through brain.take_damage (so thresholds and invulnerability apply).

signal defeated
signal adds_requested(count: int)
signal health_changed(current: int, max_health: int)

@export var max_health := 420
@export var slam_radius := 3.2
@export var nova_radius := 6.0
@export var lunge_speed := 16.0
@export var walk_speed := 1.6
@export var contact_radius := 1.2   ## the lunge hurts within this distance of the boss — the lane is drawn exactly this wide
@export var lunge_lock := 0.75       ## fraction of the lunge telegraph after which its direction is fixed
@export var adds_per_phase := 1      ## rushers called at each phase change

var target: Node3D
var brain := BossBrain.new()

var _lunge_dir := Vector3.ZERO
var _hit_this_strike := false
var _flash := 0.0
var _mat := StandardMaterial3D.new()

@onready var _look := $Look as MeshInstance3D
@onready var _disc := $Telegraph as MeshInstance3D
@onready var _lane := $Lane as Node3D
@onready var _disc_mat := StandardMaterial3D.new()


func _ready() -> void:
	brain.max_health = max_health
	brain.thresholds = [0.66, 0.33]
	brain.transition_time = 1.2
	brain.attacks = moves()
	brain.phase_changed.connect(func(_p: int) -> void: adds_requested.emit(adds_per_phase))
	brain.attack_started.connect(_on_attack_started)
	brain.strike_started.connect(_on_strike_started)
	brain.died.connect(func() -> void: defeated.emit())
	brain.start(7)
	_mat.albedo_color = Color(0.55, 0.2, 0.6)
	_look.material_override = _mat
	_disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_disc.material_override = _disc_mat
	var strip := $Lane/Strip as MeshInstance3D
	strip.material_override = _disc_mat
	# The lane shows exactly where the charge hurts: 2 × contact_radius wide, as long as the charge travels.
	var reach := lunge_speed * moves()[1].strike + contact_radius
	strip.scale = Vector3(contact_radius * 2.0 / 1.6, 1.0, reach / 6.0)
	strip.position = Vector3(0, 0.03, -reach / 2.0)
	_lane.visible = false
	_disc.visible = false
	add_to_group(&"enemies")


## The move set — also what the readability test validates.
static func moves() -> Array[BossAttack]:
	var out: Array[BossAttack] = []
	for spec: Array in [[&"slam", 0.7, 0.15, 1.0, 14, 0], [&"lunge", 0.6, 0.35, 0.9, 12, 0], [&"nova", 1.0, 0.2, 1.2, 18, 1]]:
		var a := BossAttack.new()
		a.id = spec[0]
		a.telegraph = spec[1]
		a.strike = spec[2]
		a.recovery = spec[3]
		a.damage = spec[4]
		a.min_phase = spec[5]
		out.append(a)
	return out


func take_hit(damage: int, _push: Vector3) -> void:
	if brain.take_damage(damage) > 0:
		_flash = 0.08
	health_changed.emit(brain.health, brain.max_health)


func _physics_process(delta: float) -> void:
	brain.tick(delta)
	var to_target := Vector3.ZERO
	if target != null and is_instance_valid(target):
		to_target = target.global_position - global_position
		to_target.y = 0.0
	velocity = Vector3.ZERO
	var a := brain.current_attack()
	if a != null and a.id == &"lunge" and brain.is_telegraphing() and brain.state_elapsed() < a.telegraph * lunge_lock and to_target.length() > 0.1:
		_lunge_dir = to_target.normalized()
	if a != null and a.id == &"lunge" and brain.is_striking():
		velocity = _lunge_dir * lunge_speed
		_contact_damage(a)
	elif brain.is_recovering() and to_target.length() > 2.0:
		velocity = to_target.normalized() * walk_speed
	if brain.is_telegraphing() and to_target.length() > 0.05:
		look_at(global_position + to_target.normalized(), Vector3.UP)
	move_and_slide()


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	var base := Color(0.55, 0.2, 0.6)
	if brain.state == BossBrain.State.TRANSITION:
		base = Color(1, 1, 1)
	elif brain.is_telegraphing():
		base = Color(1.0, 0.45, 0.2)
	_mat.albedo_color = Color(1, 1, 1) if _flash > 0.0 else base
	_disc_mat.albedo_color = Color(1, 0.2, 0.1, 0.55 if brain.is_striking() else 0.3)
	var a := brain.current_attack()
	_disc.visible = a != null and a.id != &"lunge" and (brain.is_telegraphing() or brain.is_striking())
	_lane.visible = a != null and a.id == &"lunge" and (brain.is_telegraphing() or brain.is_striking())
	if _lane.visible and _lunge_dir.length() > 0.1:
		_lane.global_rotation = Vector3(0, atan2(-_lunge_dir.x, -_lunge_dir.z), 0)


func _on_attack_started(a: BossAttack) -> void:
	_hit_this_strike = false
	var radius := slam_radius if a.id == &"slam" else (nova_radius if a.id == &"nova" else contact_radius)
	_disc.scale = Vector3(radius, 1.0, radius)


func _on_strike_started(a: BossAttack) -> void:
	if a.id == &"lunge":
		return   # direction already locked during the telegraph
	var radius := slam_radius if a.id == &"slam" else nova_radius
	if target != null and is_instance_valid(target) and target.has_method(&"take_hit"):
		var offset := target.global_position - global_position
		offset.y = 0.0
		if offset.length() <= radius:
			target.take_hit(a.damage, offset.normalized() * 7.0)


func _contact_damage(a: BossAttack) -> void:
	if _hit_this_strike or target == null or not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	offset.y = 0.0
	if offset.length() <= contact_radius:
		_hit_this_strike = true
		target.take_hit(a.damage, _lunge_dir * 8.0)
