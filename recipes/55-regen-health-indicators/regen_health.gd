class_name RegenHealth
extends RefCounted
## Campaign-shooter health (recipe 55): damage, then after `regen_delay` seconds without being hit, health comes back
## at `regen_rate` per second — optionally only up to the top of the current "segment", so a player can't sit behind
## cover to erase everything (`segment` = 0 means a full refill). `danger()` is 0…1 for the screen effect (blood
## edges, desaturation, heartbeat) as health drops below `danger_below`.

signal damaged(amount: float, remaining: float)
signal died
signal regen_started

var max_health := 100.0
var regen_delay := 4.0     ## s after the last hit (CoD4 5 s; later games 4 → 3 s [wiki])
var regen_rate := 25.0     ## health per second
var segment := 0.0         ## > 0: regeneration stops at the next multiple of this (e.g. 25 → 25, 50, 75, 100)
var danger_below := 0.35   ## fraction of max health where the danger effect starts

var current := 100.0
var since_hit := INF
var _regenerating := false


func _init(max_hp: float = 100.0) -> void:
	max_health = max_hp
	current = max_hp


func is_dead() -> bool:
	return current <= 0.0


func take_damage(amount: float) -> float:
	if amount <= 0.0 or is_dead():
		return 0.0
	var applied := minf(amount, current)
	current -= applied
	since_hit = 0.0
	_regenerating = false
	damaged.emit(applied, current)
	if current <= 0.0:
		died.emit()
	return applied


func tick(delta: float) -> void:
	if is_dead():
		return
	since_hit += delta
	if since_hit < regen_delay or current >= _cap():
		return
	if not _regenerating:
		_regenerating = true
		regen_started.emit()
	current = minf(current + regen_rate * delta, _cap())


## 0 when health is above danger_below, 1 at zero health.
func danger() -> float:
	var f := current / max_health
	return clampf(1.0 - f / danger_below, 0.0, 1.0) if f < danger_below else 0.0


func _cap() -> float:
	if segment <= 0.0:
		return max_health
	# the top of the segment health is in now (a hit that lands exactly on a boundary regenerates to it)
	return minf(ceilf(current / segment - 1e-6) * segment, max_health) if current > 0.0 else 0.0


## Where a hit came from, relative to where the camera looks, for the damage indicator: degrees, 0 = in front,
## 90 = right, 180 = behind, −90 = left. Height is ignored.
static func direction_to(view: Basis, own_position: Vector3, attacker: Vector3) -> float:
	var to := attacker - own_position
	to.y = 0.0
	var fwd := -view.z
	fwd.y = 0.0
	if to.length() < 1e-4 or fwd.length() < 1e-4:
		return 0.0
	var right := view.x
	right.y = 0.0
	var a := rad_to_deg(atan2(to.normalized().dot(right.normalized()), to.normalized().dot(fwd.normalized())))
	return a
