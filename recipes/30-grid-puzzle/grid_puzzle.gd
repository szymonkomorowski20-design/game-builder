class_name GridPuzzle
extends RefCounted
## Sokoban-style rules, independent of any scene: walls, boxes, goals, player; pushing, undo, win check.
## Level text:  #  wall   @  player   $  box   .  goal   *  box on goal   +  player on goal
## A scene renders the state and turns input actions into move(Vector2i.LEFT) etc. — tests never need the scene.

signal moved
signal solved

var walls := {}
var boxes := {}
var goals := {}
var player := Vector2i.ZERO
var moves := 0
var _history: Array = []


static func parse(rows: PackedStringArray) -> GridPuzzle:
	var p := GridPuzzle.new()
	for y in rows.size():
		for x in rows[y].length():
			var c := Vector2i(x, y)
			match rows[y][x]:
				"#": p.walls[c] = true
				"@": p.player = c
				"$": p.boxes[c] = true
				".": p.goals[c] = true
				"*":
					p.boxes[c] = true
					p.goals[c] = true
				"+":
					p.player = c
					p.goals[c] = true
	return p


## Returns false (nothing changes, no undo entry) when the move is blocked.
func move(dir: Vector2i) -> bool:
	var to := player + dir
	if walls.has(to):
		return false
	if boxes.has(to):
		var beyond := to + dir
		if walls.has(beyond) or boxes.has(beyond):
			return false
		_history.append({"player": player, "boxes": boxes.duplicate()})
		boxes.erase(to)
		boxes[beyond] = true
	else:
		_history.append({"player": player, "boxes": boxes.duplicate()})
	player = to
	moves += 1
	moved.emit()
	if is_solved():
		solved.emit()
	return true


func undo() -> bool:
	if _history.is_empty():
		return false
	var s: Dictionary = _history.pop_back()
	player = s.player
	boxes = s.boxes
	moves -= 1
	moved.emit()
	return true


func is_solved() -> bool:
	for b in boxes:
		if not goals.has(b):
			return false
	return not boxes.is_empty()
