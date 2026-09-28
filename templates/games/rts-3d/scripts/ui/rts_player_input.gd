class_name RtsPlayerInput
extends Node
## The player's hands (recipes 58, 60, 61, 65):
## - left click selects (shift toggles, a double-click takes the type on screen); a drag box takes own units over
##   buildings;
## - right click is the smart order (attack, gather, help build, move — a group gets formation targets); shift queues;
##   with a building selected, it sets the rally point;
## - A then left click: attack-move; S: stop; B: the build card (Q farm, W barracks, E stable, R town hall), then a
##   ghost that is green where the building fits and red with the reason where it doesn't; left click places, right
##   click or Esc cancels;
## - with a building selected, Q / W / E train what it makes;
## - Ctrl+1–9 assigns a control group, 1–9 recalls it (twice quickly: the camera jumps there).
## Observable: selection, mode, placing, drag_rect().

signal selection_changed

const DRAG_MIN := 6.0
const BUILD_CARD: Array[StringName] = [&"farm", &"barracks", &"stable", &"town_hall"]

@export var team := 0

var selection := RtsSelection.new()
var game: RtsGame
var rig: RtsCamera
var mode: StringName = &"normal"              ## normal · build_card · place · attack_move
var placing: StringName = &""
var ghost: MeshInstance3D
var ghost_why := ""
var last_order_at := Vector3.INF

var _drag_from := Vector2.INF
var _mouse := Vector2.ZERO
var _last_group := -1
var _last_group_t := -10.0


func _ready() -> void:
	game = get_parent() as RtsGame
	if not game.is_node_ready():
		await game.ready                         # children are ready before their parent
	rig = game.get_node(^"CameraRig") as RtsCamera
	selection.team = team
	selection.changed.connect(func() -> void: selection_changed.emit())
	ghost = MeshInstance3D.new()
	ghost.name = "Ghost"
	ghost.visible = false
	game.world_root.add_child.call_deferred(ghost)


func _process(_delta: float) -> void:
	selection.prune()
	if mode == &"place":
		_update_ghost()


# ---- screen helpers ----

func to_screen(o: Object) -> Vector2:
	var n := o as Node3D
	if n == null or not is_instance_valid(n) or not n.visible:
		return Vector2.INF
	var p := n.global_position + Vector3(0, 0.8, 0)
	if rig.camera.is_position_behind(p):
		return Vector2.INF
	return rig.camera.unproject_position(p)


func candidates() -> Array:
	var out: Array = []
	for u in game.units:
		if u.visible:
			out.append(u)
	for b in game.buildings:
		if b.visible:
			out.append(b)
	return out


func drag_rect() -> Rect2:
	if _drag_from == Vector2.INF or _drag_from.distance_to(_mouse) < DRAG_MIN:
		return Rect2()
	return Rect2(_drag_from, _mouse - _drag_from).abs()


func view_rect() -> Rect2:
	return get_viewport().get_visible_rect()


# ---- input ----

func _unhandled_input(event: InputEvent) -> void:
	if game.winner >= 0:
		return
	var mb := event as InputEventMouseButton
	var mm := event as InputEventMouseMotion
	if mm != null:
		_mouse = mm.position
		return
	if mb != null:
		_mouse = mb.position
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_left_down(mb)
			else:
				_left_up(mb)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if mode != &"normal":
				cancel()
			else:
				command_at(mb.position, mb.shift_pressed)
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode >= KEY_1 and key.keycode <= KEY_9:
		_group_key(key.keycode - KEY_0, key.ctrl_pressed)
		return
	if event.is_action_pressed(&"attack_move") and not selection.units().is_empty():
		mode = &"attack_move"
	elif event.is_action_pressed(&"stop"):
		for u in selection.units():
			(u as RtsUnit).orders.give(RtsOrders.make(RtsOrders.Kind.STOP))
	elif event.is_action_pressed(&"build_menu") and _selected_workers().size() > 0:
		mode = &"build_card"
	elif event.is_action_pressed(&"pause"):
		cancel()
	else:
		for i in 4:
			if event.is_action_pressed(StringName("cmd_%d" % (i + 1))):
				card_button(i)
				return


func _left_down(mb: InputEventMouseButton) -> void:
	if mode == &"place":
		place_at(mb.position, mb.shift_pressed)
	elif mode == &"attack_move":
		var at := rig.ground_point(mb.position)
		if at != Vector3.INF:
			order_group(selection.units(), at, RtsOrders.Kind.ATTACK_MOVE, mb.shift_pressed)
		mode = &"normal"
	else:
		_drag_from = mb.position


func _left_up(mb: InputEventMouseButton) -> void:
	if _drag_from == Vector2.INF:
		return
	var box := drag_rect()
	if box.size != Vector2.ZERO:
		selection.box(candidates(), box, to_screen, mb.shift_pressed)
	elif mb.double_click:
		var hit := _object_at(mb.position)
		if hit != null:
			selection.select_same_kind(candidates(), hit, view_rect(), to_screen)
	else:
		selection.click(candidates(), mb.position, to_screen, mb.shift_pressed)
	_drag_from = Vector2.INF
	if mode == &"build_card" and _selected_workers().is_empty():
		mode = &"normal"


func cancel() -> void:
	mode = &"normal"
	placing = &""
	ghost.visible = false


# ---- orders ----

## The right click at a screen point: a smart order for each selected unit (recipe 58); a building sets its rally point.
func command_at(screen: Vector2, shift: bool = false) -> void:
	var ground := rig.ground_point(screen)
	var target := _object_at(screen, true)
	var list := selection.units()
	if list.is_empty():
		for b in selection.selected:
			var bb := b as RtsBuilding
			if bb != null and bb.team == team:
				bb.rally_point = (target as Node3D).global_position if target is RtsMine else ground
		return
	if target == null:
		if ground != Vector3.INF:
			order_group(list, ground, RtsOrders.Kind.MOVE, shift)
		return
	var tpos := (target as Node3D).global_position
	var movers: Array = []
	for u in list:
		var unit := u as RtsUnit
		var o := RtsOrders.smart(team, unit.is_worker(), unit.is_worker(), target, tpos)
		if o.kind == RtsOrders.Kind.MOVE:
			movers.append(unit)
		else:
			unit.orders.give(o, shift)
	if not movers.is_empty():
		order_group(movers, tpos, RtsOrders.Kind.MOVE, shift)
	last_order_at = tpos


## A group order with formation targets (recipe 61).
func order_group(list: Array, at: Vector3, kind: RtsOrders.Kind, shift: bool = false) -> void:
	var pos: Array[Vector3] = []
	for u in list:
		pos.append((u as RtsUnit).global_position)
	var targets := RtsGroupMove.targets(pos, at, 1.4)
	for i in list.size():
		(list[i] as RtsUnit).orders.give(RtsOrders.make(kind, targets[i]), shift)
	last_order_at = at


## An object under the cursor: own and enemy units and buildings, and resources (for right clicks).
func _object_at(screen: Vector2, include_mines: bool = false) -> Object:
	var list := candidates()
	if include_mines:
		list.append_array(game.mines.filter(func(m: RtsMine) -> bool: return m.alive))
	var best: Object = null
	var bd := 28.0
	for c in list:
		var p := to_screen(c)
		if p == Vector2.INF:
			continue
		var d := p.distance_to(screen)
		if d < bd:
			bd = d
			best = c
	if best is RtsUnit and (best as RtsUnit).team == team and include_mines:
		return null                               # a right click on an own unit: just move there
	return best


# ---- the command card ----

## What the card shows now: [{kind, key, cost, enabled, why}] for the selected building, or the build card.
func card() -> Array:
	var out: Array = []
	if mode == &"build_card" or mode == &"place":
		for i in BUILD_CARD.size():
			var k := BUILD_CARD[i]
			out.append(_entry(k, i, game.rules.building(k).cost))
		return out
	var b := _selected_building()
	if b != null and b.finished:
		var trains: Array = b.trains()
		for i in trains.size():
			var k: StringName = trains[i]
			out.append(_entry(k, i, game.rules.unit(k).cost))
	return out


func _entry(kind: StringName, i: int, cost: Dictionary) -> Dictionary:
	var ok: bool = game.techs[team].available(kind)
	return {"kind": kind, "key": ["Q", "W", "E", "R"][i], "cost": cost, "enabled": ok,
		"why": "" if ok else "Wymaga: " + ", ".join(game.techs[team].missing(kind).map(func(k: StringName) -> String: return game.name_of(k)))}


func card_button(i: int) -> void:
	var c := card()
	if i >= c.size():
		return
	var k: StringName = c[i].kind
	if mode == &"build_card" or mode == &"place":
		placing = k
		mode = &"place"
		_update_ghost()
		return
	var b := _selected_building()
	if b != null:
		game.train(b, k)


func place_at(screen: Vector2, shift: bool = false) -> void:
	var at := rig.ground_point(screen)
	if at == Vector3.INF or placing == &"":
		return
	var cell := game.grid.footprint_at(at, game.rules.building(placing).size)
	var site := game.try_build(team, placing, cell, _selected_workers(), shift)
	if site != null and not shift:
		cancel()


func _update_ghost() -> void:
	if placing == &"":
		ghost.visible = false
		return
	var at := rig.ground_point(_mouse)
	if at == Vector3.INF:
		return
	var size: Vector2i = game.rules.building(placing).size
	var cell := game.grid.footprint_at(at, size)
	ghost_why = game.why_not_place(team, placing, cell)
	var box := ghost.mesh as BoxMesh
	if box == null:
		box = BoxMesh.new()
		ghost.mesh = box
	box.size = Vector3(size.x * game.rules.cell_size, 0.4, size.y * game.rules.cell_size)
	ghost.material_override = RtsLook.mat(Color(0.2, 0.9, 0.3, 0.45) if ghost_why == "" else Color(0.95, 0.2, 0.15, 0.45), true)
	ghost.position = game.grid.centre(cell, size) + Vector3(0, 0.2, 0)
	ghost.visible = true


func _selected_workers() -> Array:
	return selection.units().filter(func(u: Object) -> bool: return (u as RtsUnit).is_worker())


func _selected_building() -> RtsBuilding:
	if selection.selected.size() == 1:
		var b := selection.selected[0] as RtsBuilding
		if b != null and b.team == team:
			return b
	return null


# ---- control groups ----

func _group_key(n: int, ctrl: bool) -> void:
	if ctrl:
		selection.assign_group(n)
		return
	var now := Time.get_ticks_msec() / 1000.0
	if selection.recall_group(n) and n == _last_group and now - _last_group_t < 0.4:
		var pos: Array[Vector3] = []
		for u in selection.selected:
			pos.append((u as Node3D).global_position)
		rig.jump_to(RtsGroupMove.centroid(pos))
	_last_group = n
	_last_group_t = now
