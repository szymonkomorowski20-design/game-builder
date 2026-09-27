extends Node3D
## Arena: counts targets, wins when all are down; captures the mouse for play and frees it on pause (Esc).
## Observable: `targets_total`, `targets_left`, `completed`, `score`.

var targets_total := 0
var targets_left := 0
var completed := false
## "left/total" — read by the harness (group gb_track) so replays compare it.
var score := "0/0"

@onready var player: FpsPlayer = $Player
@onready var counter: Label = $HUD/Targets
@onready var message: Label = $HUD/Message


func _ready() -> void:
	for t in get_tree().get_nodes_in_group("targets"):
		targets_total += 1
		(t as ShootTarget).destroyed.connect(_on_destroyed)
	targets_left = targets_total
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if captured else Input.MOUSE_MODE_CAPTURED
	elif completed and event.is_action_pressed("action"):
		get_tree().reload_current_scene()


func _on_destroyed(_t: ShootTarget) -> void:
	targets_left -= 1
	_update()
	if targets_left == 0:
		completed = true
		message.text = "Wszystkie cele trafione!\nE / Enter — jeszcze raz"
		message.visible = true
		get_node("/root/Events").game_over.emit(true)


func _update() -> void:
	score = "%d/%d" % [targets_left, targets_total]
	counter.text = "Cele: %d/%d" % [targets_total - targets_left, targets_total]
