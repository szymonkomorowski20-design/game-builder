extends Node2D
## Board: loads levels from a LevelSet, turns input actions into single-cell moves, draws the grid, handles
## undo/restart/next level. Observable for tests: `level_index`, `puzzle`, `levels_solved`, `won`, `score`.
## Controls: move_* — step/push · action — undo · jump — restart level.

signal level_solved(index: int, moves: int)

@export var level_set: LevelSet = preload("res://data/levels.tres")
@export var tile := 32                  ## px per cell
@export var next_level_delay := 0.5     ## s after solving before the next level loads

var level_index := 0
var puzzle: GridPuzzle
var levels_solved := 0
var won := false
## "level/moves/solved" — read by the harness (group gb_track) so replays compare it.
var score := ""

var _next_in := -1.0

@onready var hud: Label = $HUD/Info
@onready var message: Label = $HUD/Message


func _ready() -> void:
	load_level(0)


func load_level(index: int) -> void:
	level_index = index
	puzzle = GridPuzzle.parse(level_set.rows(index))
	var board_px := Vector2(puzzle.size) * tile
	position = ((get_viewport_rect().size - board_px) / 2.0).floor()
	message.visible = false
	_update()


func _physics_process(delta: float) -> void:
	if _next_in >= 0.0:
		_next_in -= delta
		if _next_in < 0.0:
			load_level(level_index + 1)
		return
	if won:
		if Input.is_action_just_pressed("jump"):
			won = false
			levels_solved = 0
			load_level(0)
		return
	var dir := Vector2i.ZERO
	if Input.is_action_just_pressed("move_left"):
		dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("move_right"):
		dir = Vector2i.RIGHT
	elif Input.is_action_just_pressed("move_up"):
		dir = Vector2i.UP
	elif Input.is_action_just_pressed("move_down"):
		dir = Vector2i.DOWN
	if dir != Vector2i.ZERO and puzzle.move(dir):
		_after_move()
	elif Input.is_action_just_pressed("action") and puzzle.undo():
		_update()
	elif Input.is_action_just_pressed("jump"):
		load_level(level_index)


func _after_move() -> void:
	_update()
	if not puzzle.is_solved():
		return
	levels_solved += 1
	level_solved.emit(level_index, puzzle.moves)
	if level_index + 1 < level_set.count():
		message.text = "Poziom ukończony!"
		message.visible = true
		_next_in = next_level_delay
	else:
		won = true
		message.text = "Wszystkie poziomy ukończone!\nSpacja — od nowa"
		message.visible = true
		get_node("/root/Events").game_over.emit(true)


func _update() -> void:
	score = "%d/%d/%d" % [level_index, puzzle.moves, levels_solved]
	hud.text = "Poziom %d/%d · ruchy: %d · E cofnij · Spacja restart" % [level_index + 1, level_set.count(), puzzle.moves]
	queue_redraw()


func _draw() -> void:
	var t := float(tile)
	for y in puzzle.size.y:
		for x in puzzle.size.x:
			var c := Vector2i(x, y)
			var r := Rect2(Vector2(c) * t, Vector2(t, t))
			if puzzle.walls.has(c):
				draw_rect(r, Color(0.35, 0.36, 0.42))
			else:
				draw_rect(r, Color(0.16, 0.17, 0.21))
				if puzzle.goals.has(c):
					draw_circle(r.get_center(), t * 0.18, Color(0.95, 0.8, 0.3))
			if puzzle.boxes.has(c):
				var col := Color(0.4, 0.8, 0.45) if puzzle.goals.has(c) else Color(0.75, 0.5, 0.25)
				draw_rect(r.grow(-t * 0.12), col)
	draw_rect(Rect2(Vector2(puzzle.player) * t, Vector2(t, t)).grow(-t * 0.22), Color(0.45, 0.75, 1.0))
