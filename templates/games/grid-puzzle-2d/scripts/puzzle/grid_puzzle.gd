class_name GridPuzzle
extends RefCounted
## Push-box puzzle rules, independent of rendering: walls, boxes, goals, player; moves, pushes, undo, win.
## Level text:  #  wall   @  player   $  box   .  goal   *  box on goal   +  player on goal   (space) floor

var walls := {}
var boxes := {}
var goals := {}
var player := Vector2i.ZERO
var size := Vector2i.ZERO
var moves := 0
var _history: Array = []


static func parse(rows: PackedStringArray) -> GridPuzzle:
	var p := GridPuzzle.new()
	for y in rows.size():
		p.size.x = maxi(p.size.x, rows[y].length())
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
	p.size.y = rows.size()
	return p


## Returns false (nothing changes, no undo entry) when blocked.
func move(dir: Vector2i) -> bool:
	var to := player + dir
	if walls.has(to):
		return false
	var pushed := boxes.has(to)
	if pushed:
		var beyond := to + dir
		if walls.has(beyond) or boxes.has(beyond):
			return false
	_history.append({"player": player, "boxes": boxes.duplicate()})
	if pushed:
		boxes.erase(to)
		boxes[to + dir] = true
	player = to
	moves += 1
	return true


func undo() -> bool:
	if _history.is_empty():
		return false
	var s: Dictionary = _history.pop_back()
	player = s.player
	boxes = s.boxes
	moves -= 1
	return true


func is_solved() -> bool:
	if boxes.is_empty():
		return false
	for b in boxes:
		if not goals.has(b):
			return false
	return true


## Shortest solution by breadth-first search over (player, boxes). Returns the move list, or [] when unsolvable
## within `max_states`. For small levels only — it proves a level is solvable and gives the par move count.
static func solve(rows: PackedStringArray, max_states: int = 200000) -> Array[Vector2i]:
	var start := parse(rows)
	var dirs: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var key := func(pl: Vector2i, bx: Dictionary) -> String:
		var keys := bx.keys()
		keys.sort()
		return str(pl) + str(keys)
	var seen := {key.call(start.player, start.boxes): true}
	var queue: Array = [[start.player, start.boxes, [] as Array[Vector2i]]]
	var i := 0
	while i < queue.size() and seen.size() < max_states:
		var node: Array = queue[i]
		i += 1
		for d in dirs:
			var p := GridPuzzle.new()
			p.walls = start.walls
			p.goals = start.goals
			p.player = node[0]
			p.boxes = (node[1] as Dictionary).duplicate()
			if not p.move(d):
				continue
			var path: Array[Vector2i] = (node[2] as Array[Vector2i]).duplicate()
			path.append(d)
			if p.is_solved():
				return path
			var k: String = key.call(p.player, p.boxes)
			if not seen.has(k):
				seen[k] = true
				queue.append([p.player, p.boxes, path])
	return [] as Array[Vector2i]
