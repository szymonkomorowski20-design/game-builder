class_name Climber
extends Node
## Climbing for a StealthMover (recipe 67), a child of it. On the ground: jump at a wall, or sprint into it (the
## genre's "parkour up"), to grab the hold in front; a top low enough is stepped onto (a mantle), and a thin one is
## vaulted. From a roof's edge the drop intent turns into a hang ("parkour down", genre doc §1). While hanging:
## up/down climb hold by hold, left/right shimmy along the hold, jump + a side jumps to the next hold, up at a top
## climbs onto it, drop lets go, jump alone pushes off backwards. Running into a wall without sprint or jump never
## climbs: sticky climbing that does what the player didn't mean is the genre's pitfall.
##
## The body moves in timed moves between holds; while climbing the mover is switched off (`climbing = true`).
## Every move makes noise (climbing is high profile). The climber runs before the mover in each physics frame.

signal grabbed(ledge: Dictionary)
signal climbed_up
signal let_go

@export var climb_speed := 2.2          ## m/s along a move between holds
@export var min_move_time := 0.25
@export var max_move_time := 0.8
@export var mantle_max := 1.4           ## tops up to this above the feet are stepped onto directly
@export var grab_min := 0.4             ## the lowest hold a grab from the ground looks for, above the feet
@export var grab_max := 2.3             ## the highest hold a (jump) grab from the ground reaches
@export var air_grab_min := 1.2         ## in the air, holds at hand height: from here…
@export var air_grab_max := 2.6         ## …to here above the feet
@export var reach_up := 1.6             ## the next hold above, from a hang
@export var reach_down := 1.6
@export var shimmy_step := 0.4
@export var shimmy_margin := 0.25       ## a hold must go on this far past the step
@export var side_jumps: Array[float] = [1.0, 1.4, 1.8, 2.2]
@export var eject_out := 4.0            ## m/s away from the wall when pushing off
@export var eject_up := 4.0
@export var climb_noise := 4.0          ## m of noise per move

var probe := LedgeProbe.new()
## Observable for tests: none / hang / move.
var state: StringName = &"none"
var ledge: Dictionary = {}
var moves := 0

var _mover: StealthMover
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _t := 0.0
var _duration := 0.0
var _after: StringName = &"hang"
var _arc := 0.0
var _next: Dictionary = {}


func _ready() -> void:
	_mover = get_parent() as StealthMover
	process_physics_priority = -1


func _physics_process(delta: float) -> void:
	if _mover == null:
		return
	match state:
		&"none":
			_try_start()
		&"hang":
			_hang_input()
		&"move":
			_advance(delta)


## Snap into a hang on the hold nearest to `hands` (the hold's top) on a wall along `facing` — for tests, spawns and
## cutscenes. False when there is no hold there.
func hang_at(hands: Vector3, facing: Vector3) -> bool:
	var origin := hands + Vector3.DOWN * probe.hang_below - facing.normalized() * probe.hang_gap
	var l := probe.find(_space(), origin, facing, hands.y - 0.3, hands.y + 0.3, _exclude())
	if l.is_empty() or not l.can_hang:
		return false
	_mover.climbing = true
	_mover.teleport(l.hang)
	_enter_hang(l)
	return true


func _try_start() -> void:
	var jump := _just(&"jump")
	var sprint := _held(&"sprint")
	var drop := _just(&"drop")
	var dir := _mover.wish_direction(_stick())
	if dir == Vector3.ZERO:
		return
	var feet := _mover.global_position
	if _mover.is_on_floor():
		if drop and _mover.state == "edge":
			# Parkour down: look back at the edge from just past it, and hang from it.
			var out := feet + dir * (probe.hang_gap + 0.6) + Vector3.DOWN * probe.hang_below
			var edge := probe.find(_space(), out, -dir, feet.y - 0.3, feet.y + 0.3, _exclude())
			if not edge.is_empty() and edge.can_hang:
				_start_move(edge.hang, edge, &"hang", 0.0)
				return
		if not (jump or sprint):
			return
		var low := feet.y + grab_min
		for attempt in 3:
			var l := probe.find(_space(), feet, dir, low, feet.y + grab_max, _exclude())
			if l.is_empty():
				return
			if l.kind == &"top" and float(l.height) <= mantle_max and l.can_stand:
				_start_move(l.stand, l, &"stand", 0.0)
				return
			if l.can_hang and float(l.height) > mantle_max:
				_start_move(l.hang, l, &"hang", 0.0)
				return
			low = float(l.top_y) + 0.3    # a hold too low to use (a knee-high lip): look above it
	elif jump or sprint:
		var l := probe.find(_space(), feet, dir, feet.y + air_grab_min, feet.y + air_grab_max, _exclude())
		if not l.is_empty() and l.can_hang:
			_start_move(l.hang, l, &"hang", 0.0)


func _hang_input() -> void:
	var n: Vector3 = ledge.normal
	var facing := -n
	var right := facing.cross(Vector3.UP).normalized()
	var input := _stick()
	var at := _mover.global_position
	var top_y := float(ledge.top_y)
	if _just(&"drop"):
		_release(Vector3.ZERO)
		return
	if _just(&"jump"):
		if absf(input.x) > 0.5:
			var side := right * signf(input.x)
			for d in side_jumps:
				var l := probe.find(_space(), at + side * d, facing, top_y - 1.0, top_y + 1.0, _exclude())
				if not l.is_empty() and l.can_hang:
					_start_move(l.hang, l, &"hang", 0.4)
					return
			return
		_release(n * eject_out + Vector3.UP * eject_up)
		return
	if input.y < -0.5:
		var up := probe.find(_space(), at, facing, top_y + 0.45, top_y + reach_up, _exclude())
		if not up.is_empty() and up.can_hang:
			_start_move(up.hang, up, &"hang", 0.0)
		elif ledge.kind == &"top" and ledge.can_stand:
			_start_move(ledge.stand, ledge, &"stand", 0.0)
	elif input.y > 0.5:
		var down := probe.find(_space(), at, facing, top_y - reach_down, top_y - 0.45, _exclude())
		if not down.is_empty() and down.can_hang:
			_start_move(down.hang, down, &"hang", 0.0)
	elif absf(input.x) > 0.5:
		var side := right * signf(input.x)
		var ahead := probe.find(_space(), at + side * (shimmy_step + shimmy_margin), facing, top_y - 0.25,
				top_y + 0.25, _exclude())
		if ahead.is_empty() or not ahead.can_hang:
			return
		var l := probe.find(_space(), at + side * shimmy_step, facing, top_y - 0.25, top_y + 0.25, _exclude())
		if not l.is_empty() and l.can_hang:
			_start_move(l.hang, l, &"hang", 0.0)


func _start_move(to: Vector3, l: Dictionary, after: StringName, arc: float) -> void:
	_from = _mover.global_position
	_to = to
	_t = 0.0
	_duration = clampf(_from.distance_to(_to) / climb_speed, min_move_time, max_move_time)
	_after = after
	_arc = arc
	_next = l
	state = &"move"
	moves += 1
	_mover.climbing = true
	_mover.velocity = Vector3.ZERO
	_face(-(l.normal as Vector3))
	_mover.noise_made.emit(_mover.global_position, climb_noise)


func _advance(delta: float) -> void:
	_t += delta
	var k := clampf(_t / _duration, 0.0, 1.0)
	var s := smoothstep(0.0, 1.0, k)
	var pos := _from.lerp(_to, s) + Vector3.UP * _arc * sin(PI * k)
	if _after == &"stand":
		# Up first, then over the edge: a straight line would cut through the corner.
		var rise := smoothstep(0.0, 1.0, clampf(k / 0.6, 0.0, 1.0))
		var over := smoothstep(0.0, 1.0, clampf((k - 0.5) / 0.5, 0.0, 1.0))
		pos = Vector3(lerpf(_from.x, _to.x, over), lerpf(_from.y, _to.y + 0.05, rise), lerpf(_from.z, _to.z, over))
	_mover.global_position = pos
	if k < 1.0:
		return
	if _after == &"stand":
		state = &"none"
		ledge = {}
		_mover.climbing = false
		_mover.teleport(_to + Vector3.UP * 0.05)
		climbed_up.emit()
	else:
		_enter_hang(_next)


func _enter_hang(l: Dictionary) -> void:
	ledge = l
	state = &"hang"
	_face(-(l.normal as Vector3))
	grabbed.emit(l)


func _release(v: Vector3) -> void:
	state = &"none"
	ledge = {}
	_mover.climbing = false
	_mover.velocity = v
	let_go.emit()


func _face(dir: Vector3) -> void:
	var body := _mover.get_node_or_null("Body") as Node3D
	if body != null and dir.length_squared() > 1e-6:
		body.rotation.y = atan2(-dir.x, -dir.z)


func _space() -> PhysicsDirectSpaceState3D:
	return _mover.get_world_3d().direct_space_state


func _exclude() -> Array[RID]:
	var e: Array[RID] = [_mover.get_rid()]
	return e


func _stick() -> Vector2:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		if not InputMap.has_action(a):
			return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _held(action: StringName) -> bool:
	return InputMap.has_action(action) and Input.is_action_pressed(action)


func _just(action: StringName) -> bool:
	return InputMap.has_action(action) and Input.is_action_just_pressed(action)
