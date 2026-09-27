class_name BoonPool
extends RefCounted
## Picks the boons offered after a room: up to `count` distinct ones the player doesn't own, excluding synergies whose
## required tags the player hasn't collected yet, each with a rarity rolled from `rarity_weights`. `luck` (0 = none)
## raises the weight of rarer tiers: weight × (1 + luck × tier). Deterministic for a given seed, so a run can be
## replayed and tests can pin offers.

var boons: Array[Boon] = []
var rarity_weights := {Boon.Rarity.COMMON: 70.0, Boon.Rarity.RARE: 24.0, Boon.Rarity.EPIC: 5.0, Boon.Rarity.LEGENDARY: 1.0}
var luck := 0.0


func eligible(owned: Array[StringName]) -> Array[Boon]:
	var owned_tags := {}
	for b in boons:
		if owned.has(b.id):
			for t in b.tags:
				owned_tags[t] = true
	return boons.filter(func(b: Boon) -> bool:
		return not owned.has(b.id) and b.requires_tags.all(func(t: StringName) -> bool: return owned_tags.has(t)))


func offer(seed: int, owned: Array[StringName], count: int = 3) -> Array[BoonOffer]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var candidates := eligible(owned)
	var out: Array[BoonOffer] = []
	while out.size() < count and not candidates.is_empty():
		var i := rng.randi_range(0, candidates.size() - 1)
		out.append(BoonOffer.new(candidates[i], _roll_rarity(rng)))
		candidates.remove_at(i)
	return out


func _roll_rarity(rng: RandomNumberGenerator) -> Boon.Rarity:
	var total := 0.0
	var weights := {}
	for r: Boon.Rarity in rarity_weights:
		weights[r] = float(rarity_weights[r]) * (1.0 + luck * int(r))
		total += weights[r]
	var roll := rng.randf() * total
	for r: Boon.Rarity in weights:
		roll -= weights[r]
		if roll < 0.0:
			return r
	return Boon.Rarity.COMMON
