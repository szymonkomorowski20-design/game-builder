class_name GunModel
extends RefCounted
## Gun handling without any 3D in it (recipe 53): fire rate, magazine and reserve, tactical/empty reload (cancellable),
## spread (hip ↔ aim-down-sights, bloom per shot, recovery, an accurate first shot after a rest), a recoil pattern, and
## damage with range falloff and hit-zone multipliers. The host calls tick(delta, trigger_down) every physics frame and
## turns each returned Shot into a ray (recipe 54) and a camera kick. Deterministic for a seed.

signal fired(shot: Shot)
signal dry_fired                  ## trigger on an empty magazine (play the click)
signal reload_started(seconds: float)
signal reloaded(loaded: int)
signal reload_cancelled

class Shot:
	var index := 0                ## position in the current burst (0 = first shot)
	var spread_deg := 0.0         ## cone half-angle the shot was drawn from
	var offset := Vector2.ZERO    ## this shot's direction offset inside the cone, degrees (x yaw, y pitch)
	var kick := Vector2.ZERO      ## camera recoil to apply now, degrees (x yaw, y pitch up)

var stats: GunStats
var ammo := 0
var reserve := 0
var ads := 0.0                    ## 0 = hip, 1 = fully aiming
var bloom := 0.0
var burst := 0                    ## shots since the last rest (recoil pattern index)
var reload_left := 0.0            ## > 0 while reloading
var kick_accumulated := Vector2.ZERO

var _cooldown := 0.0
var _since_shot := INF
var _was_down := false
var _wants_ads := false
var _reload_total := 0.0
var _rng := RandomNumberGenerator.new()


func _init(gun: GunStats = null, rng_seed: int = 1) -> void:
	stats = gun if gun != null else GunStats.new()
	ammo = stats.magazine
	reserve = stats.reserve
	_rng.seed = rng_seed


func set_ads(on: bool) -> void:
	_wants_ads = on


func is_reloading() -> bool:
	return reload_left > 0.0


## Starts a reload: tactical if rounds are left, empty otherwise. Refused with a full magazine or no reserve.
func reload() -> bool:
	if is_reloading() or ammo >= stats.magazine or reserve <= 0:
		return false
	_reload_total = stats.reload_tactical if ammo > 0 else stats.reload_empty
	reload_left = _reload_total
	reload_started.emit(_reload_total)
	return true


## Sprinting, swapping or being staggered cancels a reload: nothing is loaded.
func cancel_reload() -> void:
	if is_reloading():
		reload_left = 0.0
		reload_cancelled.emit()


## The cone half-angle a shot fired now would use.
func current_spread() -> float:
	return lerpf(stats.hip_spread, stats.ads_spread, ads) + bloom


func damage_at(distance: float, zone: StringName = &"body") -> float:
	var k := 1.0
	if distance > stats.falloff_start:
		var t := clampf((distance - stats.falloff_start) / maxf(stats.falloff_end - stats.falloff_start, 0.001), 0.0, 1.0)
		k = lerpf(1.0, stats.falloff_min, t)
	match zone:
		&"head":
			k *= stats.headshot_mult
		&"limb":
			k *= stats.limb_mult
	return stats.damage * k


## Advances time; fires if the trigger allows. Returns the shots fired this frame (usually 0 or 1).
func tick(delta: float, trigger_down: bool) -> Array[Shot]:
	var out: Array[Shot] = []
	var target := 1.0 if _wants_ads else 0.0
	ads = move_toward(ads, target, delta / maxf(stats.ads_time, 0.001))
	if is_reloading():
		reload_left -= delta
		if reload_left <= 1e-4:
			reload_left = 0.0
			var loaded := mini(stats.magazine - ammo, reserve)
			ammo += loaded
			reserve -= loaded
			reloaded.emit(loaded)
	_cooldown -= delta
	_since_shot += delta
	var pressed := trigger_down and not _was_down
	_was_down = trigger_down
	if _since_shot >= stats.first_shot_rest:
		burst = 0
	if not (trigger_down and (stats.automatic or pressed)):
		bloom = maxf(bloom - stats.bloom_recovery * delta, 0.0)
		kick_accumulated = kick_accumulated.lerp(Vector2.ZERO, clampf(stats.recoil_recovery * delta * 10.0, 0.0, 1.0))
		return out
	if is_reloading() or _cooldown > 1e-4:
		return out
	if ammo <= 0:
		if pressed:
			dry_fired.emit()
		return out
	if _since_shot >= stats.first_shot_rest:
		bloom = 0.0
	var shot := Shot.new()
	shot.index = burst
	shot.spread_deg = current_spread()
	var a := _rng.randf() * TAU
	var r := sqrt(_rng.randf()) * shot.spread_deg     # uniform over the disc of the cone's cross-section
	shot.offset = Vector2(cos(a), sin(a)) * r
	var pattern := stats.recoil_pattern
	var kick := pattern[mini(burst, pattern.size() - 1)] if not pattern.is_empty() else Vector2.ZERO
	shot.kick = kick * lerpf(1.0, stats.recoil_ads_scale, ads)
	kick_accumulated += shot.kick
	ammo -= 1
	burst += 1
	bloom = minf(bloom + stats.bloom_per_shot, stats.bloom_max)
	# Inside a burst the overshoot (< one frame) carries over, so rates between frames stay exact; a shot after a
	# pause starts the clock fresh (no credit for the idle time).
	_cooldown = (_cooldown if _cooldown > -delta + 1e-9 else 0.0) + stats.shot_interval()
	_since_shot = 0.0
	out.append(shot)
	fired.emit(shot)
	return out
