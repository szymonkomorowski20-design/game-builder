class_name BossAttack
extends Resource
## One boss move: a telegraph the player can read (animation + sound/VFX), the strike that hurts, and a recovery —
## the window in which the player punishes. `min_phase` holds a move back until the fight escalates.

@export var id: StringName = &""
@export var telegraph := 0.6    ## s of warning before it can hit
@export var strike := 0.2       ## s during which it hurts
@export var recovery := 0.8     ## s of opening after it
@export var weight := 1.0
@export var min_phase := 0
@export var damage := 10
