class_name GuardSenses
extends Node3D
## A guard's eyes and ears (recipe 68). Put it on the guard at eye height, looking along the guard's −Z. Every
## `think_every` s it tests the target's test points (chest and head, not a cloud of bones: players must be able to
## predict what a guard sees, genre doc §3) against the VisionCone zones and a clear line of sight, and feeds the best
## rate into the AwarenessMeter. The target's `stealth_cues()` (recipe 66) says whether it sneaks, sprints, stands in
## shadow or is blended into a crowd. `hear(at, radius)` takes a noise — connect the player's `noise_made` — and
## passes it on only when a walkable path to the guard is shorter than the radius.

signal noticed(level: int)
signal heard(at: Vector3, radius: float)

@export var target_path: NodePath
## What blocks sight: the world, plus the target's layer so a ray that reaches the target counts as clear.
@export_flags_3d_physics var sight_mask := 3
@export var test_heights: Array[float] = [1.2, 1.7]
@export var think_every := 0.1

var cone := VisionCone.new()
var meter := AwarenessMeter.new()
## Set by the brain (recipe 69): &"alert", &"caution" or &"".
var guard_state: StringName = &""
## The game's multiplier on the rate: notoriety (recipe 72's `effect().notice`), difficulty.
var notice_scale := 1.0
var seen := false
var zone_seen: StringName = &""
var clock := 0.0

var _since := 0.0


func _physics_process(delta: float) -> void:
	clock += delta
	_since += delta
	if _since < think_every:
		return
	var dt := _since
	_since = 0.0
	look(dt)


## One look over `dt` seconds (tests call it directly).
func look(dt: float) -> void:
	var target := get_node_or_null(target_path) as Node3D
	var best := 0.0
	var best_zone: StringName = &""
	if target != null:
		var cues: Dictionary = target.call(&"stealth_cues") if target.has_method(&"stealth_cues") else {}
		var forward := -global_transform.basis.z
		for h in test_heights:
			var p := target.global_position + Vector3.UP * h
			var z := cone.zone(global_position, forward, p)
			if z == &"" or not _line_clear(p, target):
				continue
			var r := cone.rate(z, global_position.distance_to(p), cues, guard_state) * notice_scale
			if r > best:
				best = r
				best_zone = z
	seen = best > 0.0
	zone_seen = best_zone
	var before := meter.level()
	meter.update(best, dt, target.global_position if seen else Vector3.ZERO, clock)
	var after := meter.level()
	if after > before:
		noticed.emit(after)


## A noise of `radius` metres at `at`: heard when the walkable way from it to the guard's feet is short enough.
func hear(at: Vector3, radius: float) -> void:
	var d := Hearing.distance(get_world_3d().navigation_map, at, _feet())
	if Hearing.hears(radius, d):
		heard.emit(at, radius)


func _feet() -> Vector3:
	var body := get_parent() as Node3D
	return body.global_position if body != null else global_position


func _line_clear(point: Vector3, target: Node3D) -> bool:
	var exclude: Array[RID] = []
	var body := get_parent() as CollisionObject3D
	if body != null:
		exclude.append(body.get_rid())
	var q := PhysicsRayQueryParameters3D.create(global_position, point, sight_mask, exclude)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or hit.collider == target
