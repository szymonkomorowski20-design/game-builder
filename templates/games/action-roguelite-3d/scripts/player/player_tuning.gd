class_name PlayerTuning
extends Resource
## Every number that shapes how the hero feels. The spec's Tuning table maps 1:1 to these fields.

@export var move_speed := 6.0          ## m/s (the "speed" stat base)
@export var max_health := 60           ## the "max_health" stat base
@export var attack_power := 1.0        ## multiplies combo damage (the "attack_power" stat base)
@export var dash_speed := 15.0         ## m/s during the burst
@export var dash_duration := 0.17      ## s — distance ≈ speed × duration ≈ 2.5 m
@export var dash_cooldown := 0.45      ## s from the dash's start
@export var dash_iframes_after := 0.06 ## s of invulnerability after the burst ends
@export var hurt_iframes := 0.6        ## s of invulnerability after taking a hit
@export var knockback_decay := 30.0    ## m/s² — how fast a shove wears off


func base_stats() -> Dictionary:
	return {&"speed": move_speed, &"max_health": float(max_health), &"attack_power": attack_power}
