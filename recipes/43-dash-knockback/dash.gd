class_name Dash
extends RefCounted
## A dash: a burst at `speed` for `duration`, then `cooldown` before the next one (counted from the dash's start).
## Invulnerable while dashing plus `iframes_after`. Pure — the body asks `velocity()` and `is_invulnerable()` every
## physics frame and calls `tick(delta)`.

var speed := 520.0          ## px/s
var duration := 0.16        ## s
var cooldown := 0.6         ## s, from the dash's start
var iframes_after := 0.05   ## s of invulnerability after the burst ends

var _dir := Vector2.ZERO
var _since_start := INF


## Starts a dash toward `dir` (normalized; zero = no dash). Returns false during the cooldown.
func try_start(dir: Vector2) -> bool:
	if dir == Vector2.ZERO or _since_start < cooldown:
		return false
	_dir = dir.normalized()
	_since_start = 0.0
	return true


func tick(delta: float) -> void:
	_since_start += delta


func is_dashing() -> bool:
	return _since_start < duration


func is_invulnerable() -> bool:
	return _since_start < duration + iframes_after


func velocity() -> Vector2:
	return _dir * speed if is_dashing() else Vector2.ZERO


func cooldown_left() -> float:
	return maxf(cooldown - _since_start, 0.0)
