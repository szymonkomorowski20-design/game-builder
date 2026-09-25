class_name Hitbox
extends Area2D
## Deals damage to Hurtboxes it overlaps. Lives on collision layer 3 ("hitboxes"); detects nothing
## itself (mask 0) — Hurtboxes do the detecting, so one hit is reported once, by the victim, which
## then calls `on_hit_landed` so the attacker can react (a projectile disappears, a combo counts).

@export var damage: int = 1


func _init() -> void:
	collision_layer = 1 << 2   # layer 3: hitboxes
	collision_mask = 0
	monitoring = false
	monitorable = true


## Called by the Hurtbox that took this hit. Override in attackers that react to landing a hit.
func on_hit_landed(_hurtbox: Area2D, _applied: int) -> void:
	pass
