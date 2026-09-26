class_name TopDownEnemy
extends CharacterBody2D
## Chases the player and hurts on contact (the player's invulnerability limits how often). Dies at 0 health.

signal died(enemy: TopDownEnemy)

@export var move_speed: float = 60.0     ## px/s — slower than the player so it can be escaped
@export var max_health: int = 2
@export var contact_damage: int = 1

var target: Node2D
var health: int


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	$Hurt.body_entered.connect(_on_hurt_body)


func _physics_process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	velocity = global_position.direction_to(target.global_position) * move_speed
	move_and_slide()
	# Staying in contact keeps hurting once the player's invulnerability ends.
	for body in $Hurt.get_overlapping_bodies():
		_on_hurt_body(body)


func _on_hurt_body(body: Node2D) -> void:
	if body is TopDownPlayer:
		body.take_damage(contact_damage)


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	if health <= 0:
		died.emit(self)
		queue_free()
