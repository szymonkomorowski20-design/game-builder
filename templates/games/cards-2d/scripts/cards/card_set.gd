class_name CardSet
extends Resource
## Card definitions and the starting deck as data (data/cards.tres). Each card: name, cost, damage, block, text.

@export var cards: Dictionary = {}                      ## id -> {"name", "cost", "damage", "block"}
@export var starting_deck: PackedStringArray = PackedStringArray()


func cost(id: String) -> int:
	return int(cards[id].get("cost", 0))


func damage(id: String) -> int:
	return int(cards[id].get("damage", 0))


func block(id: String) -> int:
	return int(cards[id].get("block", 0))


func label(id: String) -> String:
	var c: Dictionary = cards[id]
	var parts: PackedStringArray = []
	if damage(id) > 0:
		parts.append("%d obr." % damage(id))
	if block(id) > 0:
		parts.append("%d bloku" % block(id))
	return "%s (%d)\n%s" % [c.get("name", id), cost(id), ", ".join(parts)]
