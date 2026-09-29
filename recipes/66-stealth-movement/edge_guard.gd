class_name EdgeGuard
extends RefCounted
## Walking off a roof by accident is the classic parkour complaint; one series decoupled crouching from parkour for
## exactly this reason (genre doc §1). The guard looks at the floor a little ahead of the feet and decides: a small
## step down is fine, a real drop needs an intent — jump, drop, or (optionally) sprinting, which jumps the gap for the
## player the way a high-profile run does.

enum { GO, STOP, JUMP, DROP }


static func decide(drop_height: float, step_down_max: float, jump_pressed: bool, drop_pressed: bool,
		sprinting: bool, auto_jump_when_sprinting: bool) -> int:
	if drop_height <= step_down_max:
		return GO
	if jump_pressed:
		return JUMP
	if drop_pressed:
		return DROP
	if sprinting and auto_jump_when_sprinting:
		return JUMP
	return STOP


## How far below the feet the floor is, `ahead` metres along `dir`: a ray from waist height down to `max_probe` below
## the feet. INF when there is nothing within reach (a real edge). Bodies in `exclude` (the player's own) are skipped.
static func probe_drop(space: PhysicsDirectSpaceState3D, feet: Vector3, dir: Vector3, ahead: float, max_probe: float,
		mask: int, exclude: Array[RID] = []) -> float:
	var flat := Vector3(dir.x, 0.0, dir.z)
	if flat.length_squared() < 1e-6:
		return 0.0
	var start := feet + flat.normalized() * ahead + Vector3.UP * 0.5
	var q := PhysicsRayQueryParameters3D.create(start, start + Vector3.DOWN * (max_probe + 0.5), mask, exclude)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return INF
	return feet.y - (hit.position as Vector3).y
