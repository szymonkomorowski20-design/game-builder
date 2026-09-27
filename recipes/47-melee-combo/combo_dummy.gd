class_name ComboDummy
extends CharacterBody3D
## A training dummy: records every hit (damage in order) and flashes. Real enemies route take_hit() into their
## Health (recipe 05) — with invulnerability_time 0, or the second and third swings of a combo are ignored.

var hits: Array[int] = []
var pushed := Vector3.ZERO
var _flash := 0.0

@onready var _look := get_node_or_null("Look") as MeshInstance3D


func take_hit(damage: int, push: Vector3) -> void:
	hits.append(damage)
	pushed += push
	_flash = 0.12


func _process(delta: float) -> void:
	if _look == null:
		return
	_flash = maxf(_flash - delta, 0.0)
	_look.scale = Vector3.ONE * (1.15 if _flash > 0.0 else 1.0)
