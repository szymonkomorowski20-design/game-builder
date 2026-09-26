class_name Bullet
extends Area2D
## Straight-flying bullet: damages the first enemy it touches, stops at walls, expires after `lifetime`.

var direction := Vector2.RIGHT
var speed := 420.0
var damage := 1
var lifetime := 1.2


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion():
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		body.take_damage(damage)
	queue_free()   # enemies and walls both stop the bullet
