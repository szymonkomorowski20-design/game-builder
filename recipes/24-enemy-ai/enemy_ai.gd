class_name EnemyAI
extends CharacterBody2D
## Classic enemy: PATROL between points → CHASE when it SEES the target (range + line of sight through walls) →
## ATTACK in range → keeps chasing the last seen position for `lose_time` → RETURN → PATROL.
## Decision logic is in decide() (pure, unit-testable); movement in _physics_process.

signal attacked
signal mode_changed(mode: int)

enum Mode { PATROL, CHASE, ATTACK, RETURN }

@export var target: Node2D
@export var patrol_points: PackedVector2Array = PackedVector2Array()
@export var speed := 60.0
@export var chase_speed := 110.0
@export var sight_range := 160.0
@export var attack_range := 28.0
@export var attack_cooldown := 0.6
@export var lose_time := 1.2
@export_flags_2d_physics var sight_mask := 1   ## layers that block sight (walls)

var mode: int = Mode.PATROL
var _lost_for := 0.0
var _cooldown := 0.0
var _patrol_i := 0
var _last_seen := Vector2.ZERO


## Pure decision step: what should the enemy do given distance to target and whether it can see it.
func decide(dist: float, sees: bool, delta: float) -> int:
	var before := mode
	if sees and dist <= sight_range:
		_lost_for = 0.0
		mode = Mode.ATTACK if dist <= attack_range else Mode.CHASE
	elif mode == Mode.CHASE or mode == Mode.ATTACK:
		_lost_for += delta
		mode = Mode.RETURN if _lost_for >= lose_time else Mode.CHASE
	if mode != before:
		mode_changed.emit(mode)
	return mode


func can_see() -> bool:
	if target == null:
		return false
	if global_position.distance_to(target.global_position) > sight_range:
		return false
	var q := PhysicsRayQueryParameters2D.create(global_position, target.global_position, sight_mask, [get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or hit.collider == target


func _physics_process(delta: float) -> void:
	var sees := can_see()
	if sees:
		_last_seen = target.global_position
	var dist := global_position.distance_to(target.global_position) if target != null else INF
	decide(dist, sees, delta)
	_cooldown = maxf(_cooldown - delta, 0.0)
	match mode:
		Mode.PATROL:
			if not patrol_points.is_empty() and _move_to(patrol_points[_patrol_i], speed):
				_patrol_i = (_patrol_i + 1) % patrol_points.size()
		Mode.CHASE:
			_move_to(_last_seen, chase_speed)
		Mode.ATTACK:
			velocity = Vector2.ZERO
			if _cooldown == 0.0:
				_cooldown = attack_cooldown
				attacked.emit()
		Mode.RETURN:
			if patrol_points.is_empty() or _move_to(patrol_points[_patrol_i], speed):
				mode = Mode.PATROL
				mode_changed.emit(mode)
	move_and_slide()


## Sets velocity toward `point`; returns true when (nearly) there.
func _move_to(point: Vector2, spd: float) -> bool:
	var to := point - global_position
	if to.length() < 4.0:
		velocity = Vector2.ZERO
		return true
	velocity = to.normalized() * spd
	return false
