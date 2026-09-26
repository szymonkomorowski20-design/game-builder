class_name HitStop
extends Node
## Freeze-frame on impact: Engine.time_scale drops for a few real-time milliseconds, then returns to 1.
## Overlapping requests extend the stop instead of cutting each other short. Make it an autoload ("HitStop").

@export var slow_scale := 0.05

var _active := 0


func stop(duration: float = 0.06) -> void:
	_active += 1
	Engine.time_scale = slow_scale
	# ignore_time_scale = true: the timer runs in real time even though the game is slowed down.
	await get_tree().create_timer(duration, true, false, true).timeout
	_active -= 1
	if _active == 0:
		Engine.time_scale = 1.0


func is_active() -> bool:
	return _active > 0


func _exit_tree() -> void:
	Engine.time_scale = 1.0   # never leave the game in slow motion when this node goes away
