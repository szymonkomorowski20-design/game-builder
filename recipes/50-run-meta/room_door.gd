class_name RoomDoor
extends RefCounted
## One exit of a room: what kind of room lies behind it and which reward it shows on the door (the player chooses a
## path by reward, not blind).

enum Type { COMBAT, ELITE, SHOP, REST, BOSS }
enum Reward { BOON, CURRENCY, HEAL, UPGRADE, NONE }

var type: Type
var reward: Reward


func _init(t: Type, r: Reward) -> void:
	type = t
	reward = r


func label() -> String:
	return "%s · %s" % [Type.keys()[type].capitalize(), Reward.keys()[reward].capitalize()]
