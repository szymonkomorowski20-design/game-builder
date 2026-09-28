class_name RtsSelection
extends RefCounted
## RTS selection (recipe 58): click, box, shift to add / toggle, double-click for every unit of that type on screen,
## control groups 1–9. No scene and no camera inside: the game passes the candidates (its units and buildings) and a
## `to_screen` Callable (object → screen position, Vector2.INF when it is off screen or behind the camera), so the
## same code serves a 2D or a 3D game and the tests.
##
## A candidate is any Object with the properties:
##   team: int             — whose it is (the player's is `team` here);
##   kind: StringName      — its type ("footman", "barracks"): double-click and group tabs use it;
##   is_building: bool     — box selection takes units over buildings;
##   alive: bool (optional) — a dead object drops out of the selection and the groups.
## Rules the genre settled on (see the genre doc):
##   - a box takes only the player's own objects, and only units if it caught any unit;
##   - one click on an enemy (or a neutral) selects it alone, for its information — it never mixes with own units;
##   - `limit` caps a selection (12 in older games; 0 = none, as in newer ones), keeping the first caught.

signal changed

var team := 0
var limit := 0                       ## 0: unlimited
var click_radius := 24.0             ## px around the cursor that count as a click on an object
var selected: Array[Object] = []
var groups := {}                     ## 1–9 → Array[Object]


## A click at `at`: the nearest candidate within click_radius. `add` (shift) toggles it in an own selection.
## A click on nothing clears the selection (unless `add`).
func click(candidates: Array, at: Vector2, to_screen: Callable, add: bool = false) -> void:
	var best: Object = null
	var best_d := click_radius
	for c in candidates:
		if not _alive(c):
			continue
		var p: Vector2 = to_screen.call(c)
		if p == Vector2.INF:
			continue
		var d := p.distance_to(at)
		if d <= best_d:
			best_d = d
			best = c
	if best == null:
		if not add:
			_replace([])
		return
	if not _own(best):
		_replace([best])                   # an enemy or a neutral: alone, to look at
		return
	if add and _all_own():
		var next := selected.duplicate()
		if next.has(best):
			next.erase(best)
		else:
			next.append(best)
		_replace(next)
	else:
		_replace([best])


## A drag box (screen rect): own objects inside it; only units when it caught any unit. `add` keeps the old ones.
func box(candidates: Array, rect: Rect2, to_screen: Callable, add: bool = false) -> void:
	var r := rect.abs()
	var units: Array[Object] = []
	var buildings: Array[Object] = []
	for c in candidates:
		if not _alive(c) or not _own(c):
			continue
		var p: Vector2 = to_screen.call(c)
		if p == Vector2.INF or not r.has_point(p):
			continue
		if bool(c.get(&"is_building")):
			buildings.append(c)
		else:
			units.append(c)
	var caught: Array[Object] = units if not units.is_empty() else buildings
	if add and _all_own():
		var next := selected.duplicate()
		for c in caught:
			if not next.has(c):
				next.append(c)
		_replace(next)
	elif not caught.is_empty() or not add:
		_replace(caught)


## A double-click on `on`: every own object of its kind that is on screen (`view` is the screen rect).
func select_same_kind(candidates: Array, on: Object, view: Rect2, to_screen: Callable) -> void:
	if on == null or not _own(on):
		return
	var kind: StringName = on.get(&"kind")
	var out: Array[Object] = []
	for c in candidates:
		if _alive(c) and _own(c) and c.get(&"kind") == kind:
			var p: Vector2 = to_screen.call(c)
			if p != Vector2.INF and view.has_point(p):
				out.append(c)
	_replace(out)


## Ctrl+n: the selection becomes group n (own objects only).
func assign_group(n: int) -> void:
	if _all_own():
		groups[n] = selected.duplicate()


## Shift+n: the selection joins group n.
func add_to_group(n: int) -> void:
	if not _all_own():
		return
	var g: Array = groups.get(n, [])
	for c: Variant in selected:
		if not g.has(c):
			g.append(c)
	groups[n] = g


## n: select group n (its living members). Returns whether it had any.
func recall_group(n: int) -> bool:
	var g: Array[Object] = []
	for c: Variant in groups.get(n, []):
		if _alive(c):
			g.append(c)
	groups[n] = g
	if g.is_empty():
		return false
	_replace(g)
	return true


## Drops the dead and the freed from the selection and the groups (call when something dies).
func prune() -> void:
	var keep: Array[Object] = []
	for c: Variant in selected:
		if _alive(c):
			keep.append(c)
	if keep.size() != selected.size():
		_replace(keep)
	for n in groups:
		var g: Array = groups[n]
		groups[n] = g.filter(func(c: Variant) -> bool: return _alive(c))


## The selected units (not buildings) — what an order goes to.
func units() -> Array[Object]:
	var out: Array[Object] = []
	for c: Variant in selected:
		if _alive(c) and _own(c) and not bool(c.get(&"is_building")):
			out.append(c)
	return out


func _replace(list: Array) -> void:
	var next: Array[Object] = []
	for c in list:
		if limit > 0 and next.size() >= limit:
			break
		next.append(c)
	if next == selected:
		return
	selected = next
	changed.emit()


func _own(c: Variant) -> bool:
	return int(c.get(&"team")) == team


func _all_own() -> bool:
	return selected.all(func(c: Variant) -> bool: return _alive(c) and _own(c))


static func _alive(c: Variant) -> bool:
	if c == null or not is_instance_valid(c):
		return false
	var a = c.get(&"alive")
	return a == null or bool(a)
