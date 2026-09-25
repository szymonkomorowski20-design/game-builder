class_name Health
extends Node
## Health component: add as a child of anything that can be hurt. Damage respects a short
## invulnerability window (i-frames), `died` fires exactly once, healing never exceeds max.

signal damaged(amount: int, remaining: int)
signal healed(amount: int, remaining: int)
signal died

@export var max_health: int = 5
@export var invulnerability_time: float = 0.5   ## s after a hit during which further damage is ignored

var current: int
var _invulnerable_left: float = 0.0


func _ready() -> void:
	current = max_health


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)


func is_dead() -> bool:
	return current <= 0


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


## Returns the damage actually applied (0 when ignored).
func take_damage(amount: int) -> int:
	if amount <= 0 or is_dead() or is_invulnerable():
		return 0
	var applied := mini(amount, current)
	current -= applied
	_invulnerable_left = invulnerability_time
	damaged.emit(applied, current)
	if current == 0:
		died.emit()
	return applied


func heal(amount: int) -> int:
	if amount <= 0 or is_dead():
		return 0
	var applied := mini(amount, max_health - current)
	current += applied
	if applied > 0:
		healed.emit(applied, current)
	return applied
