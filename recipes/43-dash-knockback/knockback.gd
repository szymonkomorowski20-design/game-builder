class_name Knockback
extends RefCounted
## Knockback: a hit pushes the body away from the source at `strength` px/s, decaying linearly to zero over
## `duration`. A new hit replaces the old push (they don't stack into a launch). Pure, like Dash.

var duration := 0.25   ## s

var _v0 := Vector2.ZERO
var _elapsed := INF


## Push away from `source` (a hit at the body's own position pushes nowhere).
func hit(source: Vector2, body_position: Vector2, strength: float) -> void:
	var away := (body_position - source)
	_v0 = away.normalized() * strength if away != Vector2.ZERO else Vector2.ZERO
	_elapsed = 0.0


func tick(delta: float) -> void:
	_elapsed += delta


func velocity() -> Vector2:
	if _elapsed >= duration:
		return Vector2.ZERO
	return _v0 * (1.0 - _elapsed / duration)


func active() -> bool:
	return _elapsed < duration
