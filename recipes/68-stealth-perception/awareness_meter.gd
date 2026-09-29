class_name AwarenessMeter
extends RefCounted
## A guard's awareness of the player (recipe 68): a meter that rises every moment the guard sees the player and falls
## slowly when it doesn't (genre doc §3, §5). Two thresholds make the states the player reads: `suspicious_at` (the
## guard turns and goes to check) and full (detected). Detection latches until the guard's brain (recipe 69) calls
## `reset()` after a search, so a meter that dips while the player hides doesn't cancel a hunt. The last place and
## time the player was seen are kept for the brain (honest knowledge: nothing updates while nobody sees the player).

enum { UNAWARE, SUSPICIOUS, DETECTED }

var value := 0.0
var suspicious_at := 0.4
var fall_per_s := 0.2              ## slow: 5 s from full to empty
var detected := false
var last_seen := Vector3.ZERO
var last_seen_at := -INF


## Adds `rate × delta` while the player is seen (`rate > 0`), else lets the meter fall. Returns the level after.
func update(rate: float, delta: float, seen_at: Vector3 = Vector3.ZERO, now: float = 0.0) -> int:
	if rate > 0.0:
		value = minf(value + rate * delta, 1.0)
		last_seen = seen_at
		last_seen_at = now
	else:
		value = maxf(value - fall_per_s * delta, 0.0)
	if value >= 1.0:
		detected = true
	return level()


func level() -> int:
	if detected:
		return DETECTED
	return SUSPICIOUS if value >= suspicious_at else UNAWARE


func reset() -> void:
	value = 0.0
	detected = false
