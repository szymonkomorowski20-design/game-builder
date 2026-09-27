class_name Checkpoint
extends Area2D
## A checkpoint flag: tells the level when a body of group `player` touches it; lights up when it is the active one.
## The level owns the CheckpointTracker (one per level) and decides what "active" means.

signal touched(checkpoint: Checkpoint)

@export var order := 0                                   ## later checkpoints have higher numbers
@export var idle_color := Color(0.5, 0.5, 0.55)
@export var active_color := Color(0.35, 0.9, 0.45)

@onready var flag: CanvasItem = $Flag


func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			touched.emit(self))
	set_active(false)


func set_active(on: bool) -> void:
	flag.modulate = active_color if on else idle_color
