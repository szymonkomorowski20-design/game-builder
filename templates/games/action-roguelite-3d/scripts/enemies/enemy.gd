class_name RogueEnemy
extends CharacterBody3D
## A basic enemy: an EnemyBrain decides (chase / windup / strike / recover / stagger), this body walks toward the
## player, shows the telegraph with two cues (red body + "!" above it) and deals damage when the strike starts if
## the player is still in range and in front. Hits: Health (no i-frames, so combos land), knockback, a flash, a
## stagger (only while not attacking); statuses (recipe 52) such as burn tick into the same Health.

signal died(enemy: RogueEnemy)

@export var tuning: EnemyTuning

var target: Node3D
var brain := EnemyBrain.new()
var statuses: StatusEffects

var _knock := Vector3.ZERO
var _flash := 0.0
var _mat := StandardMaterial3D.new()

@onready var health := $Health as Health
@onready var _look := $Look as MeshInstance3D
@onready var _alert := $Alert as Label3D


func _ready() -> void:
	brain.configure(tuning)
	brain.strike_started.connect(_strike)
	health.max_health = tuning.max_health
	health.current = tuning.max_health
	health.invulnerability_time = 0.0
	health.died.connect(_die)
	statuses = StatusEffects.new(StatSheet.new({&"speed": tuning.move_speed}))
	statuses.damaged.connect(func(amount: int, _id: StringName) -> void: health.take_damage(amount))
	scale = Vector3.ONE * tuning.body_scale
	_mat.albedo_color = tuning.color
	_look.material_override = _mat
	add_to_group(&"enemies")


func _physics_process(delta: float) -> void:
	statuses.tick(delta)
	var to_target := Vector3.ZERO
	if target != null and is_instance_valid(target):
		to_target = target.global_position - global_position
		to_target.y = 0.0
	brain.tick(delta, to_target.length())
	var move := Vector3.ZERO
	if brain.wants_to_move() and to_target.length() > 0.05:
		move = to_target.normalized() * statuses.sheet.value(&"speed")
	if to_target.length() > 0.05 and brain.state != EnemyBrain.State.STRIKE:
		look_at(global_position + to_target.normalized(), Vector3.UP)
	velocity = move + _knock
	_knock = _knock.move_toward(Vector3.ZERO, 25.0 * delta)
	move_and_slide()


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	var telegraph := brain.is_telegraphing()
	_alert.visible = telegraph
	_mat.albedo_color = Color(1, 1, 1) if _flash > 0.0 else (Color(1.0, 0.15, 0.1) if telegraph else tuning.color)


func take_hit(damage: int, push: Vector3) -> void:
	if health.is_dead():
		return
	health.take_damage(damage)
	_knock = push
	_flash = 0.08
	brain.hit()


func apply_status(def: StatusDef) -> void:
	if not health.is_dead():
		statuses.apply(def)


func _strike() -> void:
	if target == null or not is_instance_valid(target) or not target.has_method(&"take_hit"):
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var forward := -global_transform.basis.z
	if to_target.length() <= tuning.attack_range * 1.15 and forward.dot(to_target.normalized()) > 0.3:
		target.take_hit(tuning.damage, to_target.normalized() * tuning.knockback)


func _die() -> void:
	died.emit(self)
	queue_free()
