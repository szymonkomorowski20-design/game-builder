class_name RtsHands
extends RefCounted
## A test driver that plays with the player's real hands: mouse events at screen positions (the camera projects the
## world), keys and the project's input actions — the same events a person's mouse and keyboard produce, through the
## same RtsPlayerInput. Not game AI.
## Mouse events are pushed in the viewport's own coordinates (push_input(event, true)): Input.parse_input_event takes
## window coordinates, and a headless window is tiny, so the stretch would scale every position (×20 here).

var sc: GbScenario
var game: RtsGame
var input: RtsPlayerInput


func _init(scenario: GbScenario, g: RtsGame) -> void:
	sc = scenario
	game = g
	input = g.get_node(^"PlayerInput") as RtsPlayerInput


## Where a world point is on screen.
func screen(at: Vector3) -> Vector2:
	return input.rig.camera.unproject_position(at)


func screen_of(n: Node3D) -> Vector2:
	return input.to_screen(n)


func move_mouse(to: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = to
	ev.global_position = to
	sc.get_viewport().push_input(ev, true)
	await sc.wait_frames(1)


func _button(at: Vector2, button: MouseButton, pressed: bool, shift: bool = false, double: bool = false) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = at
	ev.global_position = at
	ev.button_index = button
	ev.pressed = pressed
	ev.shift_pressed = shift
	ev.double_click = double
	sc.get_viewport().push_input(ev, true)


func click(at: Vector2, shift: bool = false, double: bool = false) -> void:
	await move_mouse(at)
	_button(at, MOUSE_BUTTON_LEFT, true, shift, double)
	await sc.wait_frames(1)
	_button(at, MOUSE_BUTTON_LEFT, false, shift, double)
	await sc.wait_frames(2)


func right_click(at: Vector2, shift: bool = false) -> void:
	await move_mouse(at)
	_button(at, MOUSE_BUTTON_RIGHT, true, shift)
	await sc.wait_frames(1)
	_button(at, MOUSE_BUTTON_RIGHT, false, shift)
	await sc.wait_frames(2)


func drag(from: Vector2, to: Vector2) -> void:
	await move_mouse(from)
	_button(from, MOUSE_BUTTON_LEFT, true)
	await sc.wait_frames(1)
	for i in 5:
		await move_mouse(from.lerp(to, (i + 1) / 5.0))
	_button(to, MOUSE_BUTTON_LEFT, false)
	await sc.wait_frames(2)


## A key with modifiers (control groups use raw keys, not actions).
func key(code: Key, ctrl: bool = false) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.ctrl_pressed = ctrl
	ev.pressed = true
	Input.parse_input_event(ev)
	await sc.wait_frames(1)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	await sc.wait_frames(2)


## Selects these units with a drag box around them (on screen).
func box_select(nodes: Array) -> void:
	var r := Rect2(screen_of(nodes[0]), Vector2.ZERO)
	for n in nodes:
		r = r.expand(screen_of(n))
	r = r.grow(24.0)
	await drag(r.position, r.end)


func team_units(t: int, kind: StringName = &"") -> Array:
	return game.units.filter(func(u: RtsUnit) -> bool: return u.team == t and (kind == &"" or u.kind == kind))


func team_building(t: int, kind: StringName) -> RtsBuilding:
	for b in game.buildings:
		if b.team == t and b.kind == kind:
			return b
	return null


func nearest_mine(kind: StringName, to: Vector3) -> RtsMine:
	var best: RtsMine = null
	for m in game.mines:
		if m.kind == kind and m.alive and (best == null or m.global_position.distance_to(to) < best.global_position.distance_to(to)):
			best = m
	return best
