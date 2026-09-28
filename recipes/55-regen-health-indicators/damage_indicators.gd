class_name DamageIndicators
extends RefCounted
## The arcs around the crosshair that show where hits came from (recipe 55). Each hit adds an indicator at its angle
## (RegenHealth.direction_to) that fades over `lifetime`; a second hit from about the same direction refreshes it
## instead of stacking a second arc. The HUD draws `indicators` every frame (angle, alpha).

var lifetime := 1.6        ## s
var merge_within := 25.0   ## degrees — hits closer than this refresh the same arc

var indicators: Array[Dictionary] = []   # {angle, left}


func add(angle: float) -> void:
	for ind in indicators:
		if absf(angle_difference(deg_to_rad(ind.angle), deg_to_rad(angle))) <= deg_to_rad(merge_within):
			ind.angle = angle
			ind.left = lifetime
			return
	indicators.append({"angle": angle, "left": lifetime})


func tick(delta: float) -> void:
	for ind in indicators:
		ind.left -= delta
	indicators = indicators.filter(func(i: Dictionary) -> bool: return i.left > 0.0)


## Opacity of an indicator, 1 when fresh → 0 at the end of its life.
func alpha(ind: Dictionary) -> float:
	return clampf(ind.left / lifetime, 0.0, 1.0)
