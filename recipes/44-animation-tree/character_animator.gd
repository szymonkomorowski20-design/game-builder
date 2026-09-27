class_name CharacterAnimator
extends Node
## Drives an AnimationTree state machine from a body's movement: every physics frame it works out the state
## (AnimStates.state_for) and travels there when it changed. Gameplay code never calls `play()` directly.

@export var tree: AnimationTree
@export var body: CharacterBody2D
@export var run_threshold := 10.0   ## px/s — slower than this on the floor counts as idle

var current_state: StringName = &""


func _physics_process(_delta: float) -> void:
	var state := AnimStates.state_for(body.is_on_floor(), body.velocity, run_threshold)
	if state != current_state:
		current_state = state
		(tree.get("parameters/playback") as AnimationNodeStateMachinePlayback).travel(state)
