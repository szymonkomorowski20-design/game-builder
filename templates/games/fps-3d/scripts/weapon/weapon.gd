class_name Weapon
extends Node3D
## Hitscan weapon: a ray from the camera along its -Z, `weapon_range` long, masked to the world (1) and targets (3).
## One shot per `fire_interval` while held; a hit on something with `take_damage` deals `damage`. Walls stop shots.
## Observable: `shots_fired`, `last_hit` (the collider of the last shot, or null).

signal fired(hit: Object)

var shots_fired := 0
var last_hit: Object = null
var _cooldown := 0.0

@onready var ray: RayCast3D = $Ray
@onready var flash: OmniLight3D = $Flash


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	flash.visible = _cooldown > _tuning().fire_interval * 0.5


func try_fire() -> bool:
	if _cooldown > 0.0:
		return false
	var t := _tuning()
	_cooldown = t.fire_interval
	ray.target_position = Vector3(0, 0, -t.weapon_range)
	ray.force_raycast_update()
	last_hit = ray.get_collider() if ray.is_colliding() else null
	if last_hit != null and last_hit.has_method("take_damage"):
		last_hit.call("take_damage", t.damage)
	shots_fired += 1
	fired.emit(last_hit)
	return true


func _tuning() -> FpsTuning:
	return (owner as FpsPlayer).tuning
