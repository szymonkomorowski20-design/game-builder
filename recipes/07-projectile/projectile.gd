class_name Projectile
extends Hitbox
## A moving Hitbox: flies straight at `speed`, disappears after `lifetime` or when a Hurtbox reports
## the hit (recipe 06 `on_hit_landed`). Detection stays on the victim — no second collision setup.

@export var speed: float = 400.0     ## px/s
@export var lifetime: float = 2.0    ## s

var direction: Vector2 = Vector2.RIGHT
var _age: float = 0.0


func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func on_hit_landed(_hurtbox: Area2D, _applied: int) -> void:
	# Deferred: we are inside the victim's physics callback.
	set_deferred("monitorable", false)
	queue_free()
