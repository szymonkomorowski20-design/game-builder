class_name GunStats
extends Resource
## One gun's numbers (recipe 53). Every value a designer tunes lives here, so a Tuning table maps 1:1 to these
## fields. Angles are degrees, times seconds, distances metres.

@export_group("Fire")
@export var rpm := 700.0                 ## rounds per minute (an assault rifle; CoD4-era rifles 700–1200 [wiki])
@export var automatic := true            ## false: one shot per trigger press
@export var magazine := 30
@export var reserve := 120               ## spare rounds carried
@export var reload_tactical := 1.8       ## s — reload with rounds still in the magazine
@export var reload_empty := 2.3          ## s — reload after emptying it (the bolt/charging handle costs time)

@export_group("Damage")
@export var damage := 40.0              ## per hit at close range: 3 body hits on a 100-HP target (CoD4-era rifles 40→30 [wiki])
@export var headshot_mult := 1.4        ## CoD4: ×1.4 most guns, ×1.5 snipers, ×1.0 shotguns [wiki]
@export var limb_mult := 0.8
@export var falloff_start := 20.0        ## m — full damage up to here
@export var falloff_end := 45.0          ## m — minimum damage from here on
@export var falloff_min := 0.75          ## fraction of damage at falloff_end and beyond (40 → 30)
@export var max_range := 150.0           ## m — the hitscan ray length

@export_group("Accuracy")
@export var hip_spread := 3.0            ## degrees — cone half-angle when firing from the hip
@export var ads_spread := 0.3            ## degrees — aiming down sights
@export var bloom_per_shot := 0.35       ## degrees added per shot in a burst
@export var bloom_max := 3.0             ## degrees
@export var bloom_recovery := 8.0        ## degrees per second while not firing
@export var first_shot_rest := 0.25      ## s without firing after which the next shot has no bloom and restarts the recoil pattern
@export var ads_time := 0.22             ## s to go fully into (or out of) aiming down sights
@export var ads_move_scale := 0.6        ## movement speed × this while fully aiming

@export_group("Recoil")
## Per-shot camera kick in degrees: x = yaw (right +), y = pitch (up +). Shots past the end repeat the last entries.
@export var recoil_pattern: Array[Vector2] = [
	Vector2(0.0, 0.9), Vector2(0.1, 0.8), Vector2(-0.15, 0.7), Vector2(0.2, 0.6), Vector2(-0.2, 0.55),
	Vector2(0.25, 0.5), Vector2(-0.3, 0.45), Vector2(0.3, 0.4),
]
@export var recoil_ads_scale := 0.6      ## recoil × this while fully aiming
@export var recoil_recovery := 0.6       ## fraction of the accumulated kick the camera returns per ~0.1 s after firing stops


func shot_interval() -> float:
	return 60.0 / maxf(rpm, 1.0)
