class_name Hurtbox
extends Area2D
## Receives hits: when a Hitbox enters, the sibling/owner Health takes the hitbox's damage.
## Masks layer 3 ("hitboxes") only; is itself on no layer.

signal hit(by: Hitbox, applied: int)

@export var health: Health


func _init() -> void:
	collision_layer = 0
	collision_mask = 1 << 2   # sees hitboxes
	monitoring = true
	monitorable = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox and health:
		var applied := health.take_damage((area as Hitbox).damage)
		hit.emit(area, applied)
		(area as Hitbox).on_hit_landed(self, applied)
