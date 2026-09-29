class_name VisionCone
extends RefCounted
## What a guard sees and how fast it notices (recipe 68). Not a plain cone: a cone widens with distance, so it sees too
## much far away and too little up close (genre doc §3). Three zones instead:
## - near: within `near_range`, almost all around — a guard doesn't miss someone at arm's length;
## - main: out to `range`, its half-angle shrinking from `main_angle_near` to `main_angle_far` with distance;
## - peripheral: wide, short and slow, to the sides.
## Each zone has a time to notice (the meter 0 → 1) for a lit, walking player; in the main zone the time grows
## linearly with distance. `rate()` turns that into meter per second and applies the player's cues. No shipped game
## publishes these numbers (genre doc, "Not established"): tune them in a playtest and keep them the same for every
## guard, so the player can learn them.

const NEAR := &"near"
const MAIN := &"main"
const PERIPHERAL := &"peripheral"

var near_range := 2.5
var near_half_angle := 150.0       ## deg
var range := 20.0
var main_angle_near := 60.0        ## deg, the half-angle at near_range
var main_angle_far := 25.0         ## deg, at range
var peripheral_range := 8.0
var peripheral_half_angle := 100.0

var time_near := 0.4               ## s to notice fully
var time_main_near := 1.0          ## at near_range…
var time_main_far := 4.0           ## …to range, linear in between
var time_peripheral := 4.0

## Multipliers on the rate, from the player's cues and the guard's state.
var in_shadow := 0.35
var sneaking := 0.6
var high_profile := 1.6
var still := 0.7
var blended_near := 0.5            ## blended into a crowd: only a guard right beside you still notices, slowly
var alerted := 2.5                 ## a guard already hunting notices much faster
var cautious := 1.4                ## after a search (recipe 69), for a while


## &"near" / &"main" / &"peripheral", or &"" when the point is outside every zone.
func zone(eye: Vector3, forward: Vector3, point: Vector3) -> StringName:
	var to := point - eye
	var d := to.length()
	if d < 1e-4:
		return NEAR
	var angle := rad_to_deg(forward.angle_to(to))
	if d <= near_range and angle <= near_half_angle:
		return NEAR
	if d <= range and angle <= main_half_angle(d):
		return MAIN
	if d <= peripheral_range and angle <= peripheral_half_angle:
		return PERIPHERAL
	return &""


func main_half_angle(distance: float) -> float:
	return lerpf(main_angle_near, main_angle_far, _far(distance))


func time_to_notice(z: StringName, distance: float) -> float:
	match z:
		NEAR:
			return time_near
		MAIN:
			return lerpf(time_main_near, time_main_far, _far(distance))
		PERIPHERAL:
			return time_peripheral
	return INF


## Meter per second. `cues`: shadow, sneaking, high_profile, still, blended (bools); `guard_state`: &"alert",
## &"caution" or &"".
func rate(z: StringName, distance: float, cues: Dictionary = {}, guard_state: StringName = &"") -> float:
	var t := time_to_notice(z, distance)
	if is_inf(t):
		return 0.0
	var r := 1.0 / t
	if cues.get("blended", false) == true:
		if z != NEAR:
			return 0.0
		r *= blended_near
	if cues.get("shadow", false) == true:
		r *= in_shadow
	if cues.get("sneaking", false) == true:
		r *= sneaking
	if cues.get("high_profile", false) == true:
		r *= high_profile
	if cues.get("still", false) == true:
		r *= still
	if guard_state == &"alert":
		r *= alerted
	elif guard_state == &"caution":
		r *= cautious
	return r


func _far(distance: float) -> float:
	return clampf((distance - near_range) / maxf(range - near_range, 0.001), 0.0, 1.0)
