class_name StateMachine
extends Node
## Node-based finite state machine: child nodes extending State are the states.
## Only the active state gets update/physics_update/handle_input. States switch with transition_to().
##
##   Player (CharacterBody2D)
##     StateMachine (initial = Idle)
##       Idle, Run, Jump, Fall   ← each a State script that reads `owner` (the player)

signal transitioned(from: StringName, to: StringName)

@export var initial_state: State

var current: State
var states: Dictionary = {}   ## StringName -> State


func _ready() -> void:
	for child in get_children():
		if child is State:
			states[StringName(child.name)] = child
			child.machine = self
	current = initial_state if initial_state != null else _first_state()
	if current != null:
		current.enter({})


func _first_state() -> State:
	for child in get_children():
		if child is State:
			return child
	return null


## Returns false (and changes nothing) for an unknown state name.
func transition_to(state_name: StringName, msg: Dictionary = {}) -> bool:
	if not states.has(state_name):
		return false
	var from: StringName = StringName(current.name) if current != null else &""
	if current != null:
		current.exit()
	current = states[state_name]
	current.enter(msg)
	transitioned.emit(from, state_name)
	return true


func _process(delta: float) -> void:
	if current != null:
		current.update(delta)


func _physics_process(delta: float) -> void:
	if current != null:
		current.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current != null:
		current.handle_input(event)
