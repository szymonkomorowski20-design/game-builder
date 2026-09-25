class_name State
extends Node
## One state of a StateMachine. Override what you need; the machine calls these only on the active state.

var machine: StateMachine


func enter(_msg: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
