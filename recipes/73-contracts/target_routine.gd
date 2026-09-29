class_name TargetRoutine
extends RefCounted
## A target's day (recipe 73, genre doc §9): a short loop of stops, each with a wait. Keep it short: testers got bored
## waiting for a long loop to come round (Hitman's Sapienza). `position_at(t)` is deterministic, so the player can learn
## it from a rooftop and a test can check it. When the target is alerted, the host sends it to its safe place instead
## (the contract fails if it gets there).

var stops: Array[Vector3] = []
var waits: Array[float] = []
var speed := 1.3


func add_stop(pos: Vector3, wait: float) -> void:
	stops.append(pos)
	waits.append(maxf(wait, 0.0))


## One full round: every wait, and every walk to the next stop (the last back to the first).
func loop_time() -> float:
	var total := 0.0
	for i in stops.size():
		total += waits[i] + _walk(i)
	return total


## Where the target is `t` seconds into its day (the day starts waiting at the first stop).
func position_at(t: float) -> Vector3:
	if stops.is_empty():
		return Vector3.ZERO
	var loop := loop_time()
	var left := fposmod(t, loop) if loop > 0.0 else 0.0
	for i in stops.size():
		if left < waits[i]:
			return stops[i]
		left -= waits[i]
		var walk := _walk(i)
		if left < walk:
			return stops[i].lerp(stops[(i + 1) % stops.size()], left / walk)
		left -= walk
	return stops[0]


## The stop the target is waiting at `t` seconds in (the window a planned strike waits for), or -1 while it walks.
func waiting_at(t: float) -> int:
	if stops.is_empty():
		return -1
	var left := fposmod(t, loop_time())
	for i in stops.size():
		if left < waits[i]:
			return i
		left -= waits[i] + _walk(i)
		if left < 0.0:
			return -1
	return -1


func _walk(i: int) -> float:
	if stops.size() < 2:
		return 0.0
	return stops[i].distance_to(stops[(i + 1) % stops.size()]) / speed
