class_name Boon
extends Resource
## An upgrade offered during a run. `tags` say what it belongs to (a school, a god, an element); `requires_tags` makes
## it a synergy that is only offered once the player owns boons of every one of those tags. Its modifiers are
## written for COMMON and scaled by RARITY_SCALE when taken at a higher rarity.

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

const RARITY_SCALE := {Rarity.COMMON: 1.0, Rarity.RARE: 1.5, Rarity.EPIC: 2.0, Rarity.LEGENDARY: 2.5}

@export var id: StringName = &""
@export var title := ""
@export_multiline var description := ""
@export var tags: Array[StringName] = []
@export var requires_tags: Array[StringName] = []
@export var modifiers: Array[StatModifier] = []


func apply(sheet: StatSheet, rarity: Rarity = Rarity.COMMON) -> void:
	var k: float = RARITY_SCALE[rarity]
	for m in modifiers:
		var scaled := m.duplicate() as StatModifier
		scaled.source = id
		# MORE is a multiplier: scale its bonus part (×1.2 at rare 1.5 → ×1.3), not the whole factor.
		scaled.value = 1.0 + (m.value - 1.0) * k if m.op == StatModifier.Op.MORE else m.value * k
		sheet.add(scaled)


func remove(sheet: StatSheet) -> void:
	sheet.remove_source(id)
