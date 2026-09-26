class_name TopDownPlayer
extends CharacterBody2D
## 8-direction movement with acceleration, shooting in the facing direction, health with invulnerability.
## Observable for tests: `health`, `shots_fired`, `facing`, `is_dead()`.

signal health_changed(health: int, max_health: int)
signal died

const BULLET := preload("res://scenes/combat/bullet.tscn")

@export var tuning: TopDownTuning = preload("res://data/topdown_tuning.tres")

var health: int
var facing := Vector2.RIGHT
var shots_fired := 0
var _cooldown := 0.0
var _invulnerable := 0.0


func _ready() -> void:
	health = tuning.max_health


func _physics_process(delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		facing = dir.normalized()
		velocity = velocity.move_toward(dir * tuning.move_speed, tuning.acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, tuning.friction * delta)
	move_and_slide()
	if Input.is_action_pressed("action") and _cooldown == 0.0:
		shoot()


func shoot() -> void:
	_cooldown = tuning.shoot_cooldown
	shots_fired += 1
	var b: Bullet = BULLET.instantiate()
	b.direction = facing
	b.speed = tuning.bullet_speed
	b.damage = tuning.bullet_damage
	b.lifetime = tuning.bullet_lifetime
	b.global_position = global_position + facing * 14.0
	var parent := get_parent().get_node_or_null("Bullets")
	(parent if parent != null else get_parent()).add_child(b)


## Returns the damage actually taken (0 while invulnerable or dead).
func take_damage(amount: int) -> int:
	if is_dead() or _invulnerable > 0.0 or amount <= 0:
		return 0
	var taken := mini(amount, health)
	health -= taken
	_invulnerable = tuning.invulnerability
	health_changed.emit(health, tuning.max_health)
	if health == 0:
		died.emit()
	return taken


func heal(amount: int) -> int:
	if is_dead():
		return 0
	var healed := mini(amount, tuning.max_health - health)
	health += healed
	health_changed.emit(health, tuning.max_health)
	return healed


func is_dead() -> bool:
	return health <= 0


func is_invulnerable() -> bool:
	return _invulnerable > 0.0
