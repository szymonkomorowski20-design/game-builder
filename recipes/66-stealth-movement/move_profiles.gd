class_name MoveProfiles
extends RefCounted
## How fast and how loud the player moves (recipe 66). A stealth game needs more than one speed: sneaking is quiet,
## sprinting is fast and "high profile" (it draws attention; genre doc §1, §4). Each profile has a speed (m/s), a noise
## radius (m) that guards can hear (recipe 68) and a high-profile flag. `pick()` turns the held intents into a profile.
## The numbers are starting values: no shipped game publishes its own (genre doc, "Not established").

const SNEAK := &"sneak"
const WALK := &"walk"
const RUN := &"run"
const SPRINT := &"sprint"

var speeds := {SNEAK: 1.6, WALK: 2.2, RUN: 4.2, SPRINT: 6.5}
var noises := {SNEAK: 0.0, WALK: 2.0, RUN: 5.0, SPRINT: 9.0}
var high_profile := {SNEAK: false, WALK: false, RUN: false, SPRINT: true}
## Below this stick deflection the player walks: a half-pushed stick walks, a full push runs.
var walk_below := 0.55
## Landing noise grows with the height fallen (m of radius per m fallen), up to a cap. Small hops are silent.
var landing_noise_per_m := 2.0
var landing_noise_max := 14.0
var silent_landing_below := 0.6


## The profile for this frame. Sprint wins over sneak (the player asked to be fast); a half-pushed stick walks.
func pick(stick: float, sprint_held: bool, sneak_held: bool) -> StringName:
	if sprint_held and stick > 0.01:
		return SPRINT
	if sneak_held:
		return SNEAK
	if stick < walk_below:
		return WALK
	return RUN


func speed(profile: StringName) -> float:
	return float(speeds.get(profile, 0.0))


func noise(profile: StringName) -> float:
	return float(noises.get(profile, 0.0))


func is_high_profile(profile: StringName) -> bool:
	return high_profile.get(profile, false) == true


func landing_noise(fall_height: float) -> float:
	if fall_height < silent_landing_below:
		return 0.0
	return minf(fall_height * landing_noise_per_m, landing_noise_max)
