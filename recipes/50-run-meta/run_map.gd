class_name RunMap
extends RefCounted
## The doors offered after each room of an area. Rules that shape pacing:
## room 0 is a single combat door with a boon (onboarding); the last room is the boss, alone; the room before it
## always offers a rest; other rooms offer 2–3 distinct doors; never a shop right after a shop; elites only from
## `elite_from`. doors(depth, seed, previous) is deterministic, so a run can be replayed from its seed.

var rooms := 10                 ## including the boss room
var elite_from := 4
var shop_chance := 0.2
var elite_chance := 0.3


func doors(depth: int, seed: int, previous: RoomDoor.Type) -> Array[RoomDoor]:
	var out: Array[RoomDoor] = []
	if depth <= 0:
		out.append(RoomDoor.new(RoomDoor.Type.COMBAT, RoomDoor.Reward.BOON))
		return out
	if depth >= rooms - 1:
		out.append(RoomDoor.new(RoomDoor.Type.BOSS, RoomDoor.Reward.NONE))
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, depth, previous])
	var count := rng.randi_range(2, 3)
	if depth == rooms - 2:
		out.append(RoomDoor.new(RoomDoor.Type.REST, RoomDoor.Reward.HEAL))
	var guard := 0
	while out.size() < count and guard < 50:
		guard += 1
		var door := _roll(rng, depth, previous)
		if not out.any(func(d: RoomDoor) -> bool: return d.type == door.type and d.reward == door.reward):
			out.append(door)
	return out


func _roll(rng: RandomNumberGenerator, depth: int, previous: RoomDoor.Type) -> RoomDoor:
	var r := rng.randf()
	if previous != RoomDoor.Type.SHOP and r < shop_chance:
		return RoomDoor.new(RoomDoor.Type.SHOP, RoomDoor.Reward.NONE)
	if depth >= elite_from and r < shop_chance + elite_chance:
		return RoomDoor.new(RoomDoor.Type.ELITE, [RoomDoor.Reward.BOON, RoomDoor.Reward.UPGRADE][rng.randi_range(0, 1)])
	var rewards := [RoomDoor.Reward.BOON, RoomDoor.Reward.CURRENCY, RoomDoor.Reward.HEAL, RoomDoor.Reward.UPGRADE]
	return RoomDoor.new(RoomDoor.Type.COMBAT, rewards[rng.randi_range(0, rewards.size() - 1)])
