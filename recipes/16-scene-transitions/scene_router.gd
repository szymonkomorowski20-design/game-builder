class_name SceneRouter
extends CanvasLayer
## Fade out → load the next scene on a background thread → swap → fade in.
## In a game make it an autoload ("Router") so it survives scene changes; call Router.change_to(path).

signal finished(path: String)

@export var fade_time := 0.25

var busy := false
var _rect: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


## Returns false if a transition is already running or the path does not exist.
func change_to(path: String) -> bool:
	if busy or not ResourceLoader.exists(path):
		return false
	busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP   # swallow clicks during the transition
	await _fade(1.0)
	ResourceLoader.load_threaded_request(path)
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	var packed := ResourceLoader.load_threaded_get(path) as PackedScene
	get_tree().change_scene_to_packed(packed)
	await get_tree().process_frame
	await _fade(0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
	finished.emit(path)
	return true


func _fade(to_alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_rect, "color:a", to_alpha, fade_time)
	await t.finished


func alpha() -> float:
	return _rect.color.a
