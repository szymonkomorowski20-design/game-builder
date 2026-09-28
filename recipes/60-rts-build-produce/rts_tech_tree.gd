class_name RtsTechTree
extends RefCounted
## What a team may build or research (recipe 60): each item lists what must be owned first — a barracks needs a town
## hall, a knight needs a blacksmith and a stable. `owned` counts buildings and finished research, so losing the only
## blacksmith locks knights again. `missing(item)` names what is missing, for the button's tooltip ("Needs: Blacksmith").

var requires := {}                   ## item → Array[StringName]
var owned := {}                      ## building or research → count


func _init(table: Dictionary = {}) -> void:
	requires = table


func add(id: StringName) -> void:
	owned[id] = int(owned.get(id, 0)) + 1


func remove(id: StringName) -> void:
	var n := int(owned.get(id, 0)) - 1
	if n <= 0:
		owned.erase(id)
	else:
		owned[id] = n


func has(id: StringName) -> bool:
	return int(owned.get(id, 0)) > 0


func missing(item: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for need in requires.get(item, []):
		if not has(need):
			out.append(need)
	return out


func available(item: StringName) -> bool:
	return missing(item).is_empty()
