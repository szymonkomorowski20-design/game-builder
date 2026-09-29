class_name FallRule
extends RefCounted
## What a landing costs (recipe 66): nothing up to `safe_height`, a share of health that rises linearly up to
## `deadly_height`, death from there on. A soft landing (hay, water, awnings: a floor in the group `soft_landing`)
## costs nothing up to `soft_max_height`. Named heights instead of "fall speed > x" in the controller, so a level
## designer knows which roofs are safe to drop from. Fall damage that works as an invisible wall is a pitfall of the
## genre (genre doc §1, §13); for "no death from falling" set `deadly_height = INF`.

enum Kind { NONE, HURT, DEAD }

var safe_height := 4.5
var deadly_height := 14.0
var soft_max_height := 40.0


## {kind: Kind, damage: 0..1 (a share of full health)}.
func outcome(height: float, soft: bool) -> Dictionary:
	if soft and height <= soft_max_height:
		return {kind = Kind.NONE, damage = 0.0}
	if height <= safe_height:
		return {kind = Kind.NONE, damage = 0.0}
	if height >= deadly_height:
		return {kind = Kind.DEAD, damage = 1.0}
	return {kind = Kind.HURT, damage = (height - safe_height) / (deadly_height - safe_height)}
