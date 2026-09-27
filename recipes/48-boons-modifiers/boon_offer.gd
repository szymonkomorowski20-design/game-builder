class_name BoonOffer
extends RefCounted
## One card in a choice: which boon, at which rarity.

var boon: Boon
var rarity: Boon.Rarity


func _init(b: Boon, r: Boon.Rarity) -> void:
	boon = b
	rarity = r
