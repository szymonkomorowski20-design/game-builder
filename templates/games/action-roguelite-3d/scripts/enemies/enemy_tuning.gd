class_name EnemyTuning
extends Resource
## One enemy type's numbers. The telegraph is the promise to the player: long enough to read (≥ 0.4 s), shown with
## two cues (colour + "!"), and never interrupted by the player's hits once it has started.

@export var max_health := 30
@export var move_speed := 3.5          ## m/s
@export var attack_range := 1.5        ## m — starts the windup when this close
@export var telegraph := 0.45          ## s
@export var strike := 0.12             ## s — the hit lands at its start
@export var recover := 0.7             ## s — the window to punish
@export var damage := 8
@export var knockback := 5.0           ## m/s given to the player
@export var body_scale := 1.0
@export var color := Color(0.85, 0.35, 0.3)
