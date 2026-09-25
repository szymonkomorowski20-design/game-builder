extends Node2D
## Something that visibly moves every frame — freezes when the tree is paused.

var ticks := 0


func _physics_process(_delta: float) -> void:
	ticks += 1
	rotation += 0.05
