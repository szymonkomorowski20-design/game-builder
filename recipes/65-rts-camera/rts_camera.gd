class_name RtsCamera
extends Node3D
## The RTS camera rig (recipe 65): a pivot on the ground (this node) with a Camera3D child looking down at `pitch`
## from `distance`. It pans with the screen edges, the arrow / WASD-style actions and a middle-mouse drag; zooms with
## the wheel between `min_distance` and `max_distance`; stays inside `bounds`; and `jump_to(point)` centres a spot (a
## minimap click, a control group's double tap, an alert).
## Pan speed grows with the zoom, so a zoomed-out view doesn't crawl. The logic is in static functions the test calls.

@export var bounds := Rect2(-50, -50, 100, 100)     ## x/z the pivot may reach
@export var pan_speed := 18.0                      ## m/s at `distance` = 20
@export var edge_margin := 12.0                    ## px from the screen edge that pan
@export var edge_pan := true                       ## off in a window that isn't focused, and in tests
@export var min_distance := 10.0
@export var max_distance := 40.0
@export var distance := 22.0
@export var pitch := 55.0                          ## degrees down
@export var zoom_step := 3.0
@export var pan_actions := ["move_left", "move_right", "move_up", "move_down"]

var camera: Camera3D
var _drag := false


func _ready() -> void:
	camera = get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)
	_place()


func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	var acts: Array = pan_actions
	if acts.size() == 4:
		dir = Input.get_vector(acts[0], acts[1], acts[2], acts[3])
	if edge_pan and dir == Vector2.ZERO:
		var vp := get_viewport()
		dir = edge_direction(vp.get_mouse_position(), vp.get_visible_rect().size, edge_margin)
	if dir != Vector2.ZERO:
		var step := pan_step(dir, pan_speed, distance, delta)
		position = clamp_to(position + Vector3(step.x, 0.0, step.y), bounds)


func _unhandled_input(event: InputEvent) -> void:
	var b := event as InputEventMouseButton
	if b != null and b.pressed:
		if b.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom(-zoom_step)
		elif b.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom(zoom_step)
	if b != null and b.button_index == MOUSE_BUTTON_MIDDLE:
		_drag = b.pressed
	var m := event as InputEventMouseMotion
	if m != null and _drag:
		var k := distance / 400.0
		position = clamp_to(position + Vector3(-m.relative.x * k, 0.0, -m.relative.y * k), bounds)


func zoom(by: float) -> void:
	distance = clampf(distance + by, min_distance, max_distance)
	_place()


## Centres the view on a point (a minimap click, an alert).
func jump_to(point: Vector3) -> void:
	position = clamp_to(Vector3(point.x, position.y, point.z), bounds)


## The ground point under a screen position (for clicks and the drag box's corners): the camera ray meets y = `ground`.
func ground_point(screen: Vector2, ground: float = 0.0) -> Vector3:
	var from := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	if absf(dir.y) < 0.0001:
		return Vector3.INF
	var t := (ground - from.y) / dir.y
	return Vector3.INF if t < 0.0 else from + dir * t


func _place() -> void:
	if camera == null:
		return
	var p := deg_to_rad(pitch)
	camera.position = Vector3(0.0, sin(p) * distance, cos(p) * distance)
	camera.rotation = Vector3(-p, 0.0, 0.0)


## −1..1 on each axis when the mouse is within `margin` px of an edge (x: left/right; y: up/down on screen = −z/+z).
static func edge_direction(mouse: Vector2, size: Vector2, margin: float) -> Vector2:
	var d := Vector2.ZERO
	if mouse.x <= margin:
		d.x = -1.0
	elif mouse.x >= size.x - margin:
		d.x = 1.0
	if mouse.y <= margin:
		d.y = -1.0
	elif mouse.y >= size.y - margin:
		d.y = 1.0
	return d.normalized() if d != Vector2.ZERO else d


## One frame's pan (x, z): faster when zoomed out, the same speed diagonally.
static func pan_step(dir: Vector2, speed: float, dist: float, delta: float) -> Vector2:
	var d := dir.normalized() if dir.length() > 1.0 else dir
	return d * speed * (dist / 20.0) * delta


static func clamp_to(p: Vector3, r: Rect2) -> Vector3:
	return Vector3(clampf(p.x, r.position.x, r.end.x), p.y, clampf(p.z, r.position.y, r.end.y))
