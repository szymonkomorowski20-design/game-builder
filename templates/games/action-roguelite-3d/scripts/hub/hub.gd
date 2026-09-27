class_name RogueHub
extends Node3D
## Between runs: a training dummy (recipe 47) to try the combo without risk, the shrine (walk up, press `action`) to
## spend banked embers on permanent upgrades, and the door that starts a run.

signal start_run_requested
signal shrine_opened

var player_near_shrine := false

@onready var start_point := $PlayerStart as Marker3D
@onready var dummy := $Dummy as ComboDummy


func _ready() -> void:
	($RunDoor as Area3D).body_entered.connect(func(b: Node3D) -> void:
		if b is RoguePlayer:
			start_run_requested.emit())
	($Shrine as Area3D).body_entered.connect(func(b: Node3D) -> void:
		if b is RoguePlayer:
			player_near_shrine = true)
	($Shrine as Area3D).body_exited.connect(func(b: Node3D) -> void:
		if b is RoguePlayer:
			player_near_shrine = false)


func _unhandled_input(event: InputEvent) -> void:
	if player_near_shrine and event.is_action_pressed(&"action"):
		shrine_opened.emit()
