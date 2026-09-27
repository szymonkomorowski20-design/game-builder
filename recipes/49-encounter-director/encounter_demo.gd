class_name EncounterDemo
extends Node2D
## A combat room run by EncounterDirector. Enemies are coloured squares on spawn points; in this demo `action`
## defeats the oldest one (a stand-in for combat, so the flow is visible). The door opens when the room is cleared.

const COLORS := {&"rusher": Color(1, 0.45, 0.35), &"archer": Color(0.4, 0.8, 0.4), &"brute": Color(0.6, 0.4, 0.9), &"summoner": Color(1, 0.85, 0.3)}

@export var depth := 4
@export var room_seed := 7

var director := EncounterDirector.new()
var enemies: Array[Node2D] = []
var waves_seen := 0
var door_open := false

@onready var _door := $Door as ColorRect
@onready var _label := $Info as Label


func _ready() -> void:
	director.kinds = [_kind(&"rusher", 1, 0), _kind(&"archer", 2, 0), _kind(&"brute", 4, 3), _kind(&"summoner", 3, 5)]
	director.wave_delay = 0.6
	director.wave_started.connect(_spawn_wave)
	director.cleared.connect(func(): door_open = true; _door.color = Color(0.3, 0.9, 0.5))
	director.start(depth, room_seed)


func _physics_process(delta: float) -> void:
	director.tick(delta)
	_label.text = "depth %d · wave %d/%d · alive %d%s" % [depth, director.wave_index + 1, director.current_plan.size(), director.alive, " · DOOR OPEN" if door_open else ""]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"action") and not enemies.is_empty():
		var e: Node2D = enemies.pop_front()
		e.queue_free()
		director.enemy_died()


func _spawn_wave(_index: int, ids: Array) -> void:
	waves_seen += 1
	for i in ids.size():
		var e := ColorRect.new()
		e.size = Vector2(22, 22)
		e.color = COLORS.get(ids[i], Color.WHITE)
		var body := Node2D.new()
		body.position = Vector2(140 + (i % 8) * 50, 110 + (i / 8) * 50)
		body.add_child(e)
		add_child(body)
		enemies.append(body)


static func _kind(id: StringName, cost: int, min_depth: int) -> EnemyKind:
	var k := EnemyKind.new()
	k.id = id
	k.cost = cost
	k.min_depth = min_depth
	return k
