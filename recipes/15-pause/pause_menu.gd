class_name PauseMenu
extends CanvasLayer
## Toggles SceneTree.paused on the "pause" action. This node runs while paused (PROCESS_MODE_ALWAYS);
## the world below keeps the default INHERIT mode and freezes.

signal pause_changed(paused: bool)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func set_paused(value: bool) -> void:
	get_tree().paused = value
	visible = value
	pause_changed.emit(value)


## Also pause when the window loses focus (players alt-tab mid-fight).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not get_tree().paused:
		set_paused(true)
