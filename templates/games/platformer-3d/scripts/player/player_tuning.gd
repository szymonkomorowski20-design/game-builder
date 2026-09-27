class_name PlayerTuning
extends Resource
## Every number that shapes how the player feels. Edited in data/player_tuning.tres (Inspector) —
## the spec's Tuning table maps 1:1 to these fields. Change values after playing, not logic. Units: metres.

@export_group("Run")
@export var run_speed: float = 6.0            ## m/s on the ground plane
@export var acceleration: float = 40.0        ## m/s² toward run_speed while a direction is held
@export var friction: float = 50.0            ## m/s² toward 0 when no direction is held
@export_range(0.0, 1.0) var air_control: float = 0.8  ## multiplier on acceleration/friction in the air
@export var turn_speed: float = 12.0          ## rad/s the body turns toward the movement direction

@export_group("Jump")
@export var jump_height: float = 1.6          ## m
@export var time_to_apex: float = 0.38        ## s
@export var fall_gravity_multiplier: float = 1.6
@export var max_fall_speed: float = 20.0      ## m/s
@export_range(0.0, 1.0) var jump_cut_multiplier: float = 0.45  ## vertical speed kept when jump is released while rising

@export_group("Forgiveness")
@export var coyote_time: float = 0.1          ## s after leaving a ledge during which jump still works
@export var jump_buffer: float = 0.12         ## s a jump press is remembered before landing
