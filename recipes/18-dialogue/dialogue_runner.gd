class_name DialogueRunner
extends RefCounted
## Branching dialogue from data (Dictionary / JSON file). Each node:
##   "id": {"speaker": "Guard", "text": "Halt!", "next": "id2"}                       — linear
##   "id": {"speaker": "Guard", "text": "...", "choices": [{"text": "Bribe", "next": "b", "if": "has_gold"}]}
##   "id": {..., "set": {"met_guard": true}}                                          — flags set on entering
## "next" missing (and no choices) ends the conversation. Flags are shared with quests/saves.

signal line_shown(speaker: String, text: String)
signal ended

var nodes: Dictionary
var flags: Dictionary
var current_id := ""


func _init(dialogue: Dictionary, shared_flags: Dictionary = {}) -> void:
	nodes = dialogue
	flags = shared_flags


func start(id: String) -> void:
	_enter(id)


func is_running() -> bool:
	return current_id != ""


func current() -> Dictionary:
	return nodes.get(current_id, {})


## Choices whose "if" flag is satisfied ("!flag" means flag must be false/missing).
func choices() -> Array:
	var out: Array = []
	for c in current().get("choices", []):
		if _condition(String(c.get("if", ""))):
			out.append(c)
	return out


## Advance a linear line. Ignored while choices are pending.
func advance() -> void:
	if not is_running() or not choices().is_empty():
		return
	_enter(String(current().get("next", "")))


func choose(index: int) -> void:
	var available := choices()
	if index < 0 or index >= available.size():
		return
	_enter(String(available[index].get("next", "")))


func _enter(id: String) -> void:
	if id == "" or not nodes.has(id):
		current_id = ""
		ended.emit()
		return
	current_id = id
	var n: Dictionary = nodes[id]
	for k in n.get("set", {}):
		flags[k] = n.set[k]
	line_shown.emit(String(n.get("speaker", "")), String(n.get("text", "")))


func _condition(expr: String) -> bool:
	if expr == "":
		return true
	if expr.begins_with("!"):
		return not bool(flags.get(expr.substr(1), false))
	return bool(flags.get(expr, false))
