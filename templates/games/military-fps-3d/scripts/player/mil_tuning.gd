class_name MilTuning
extends Resource
## Every number that shapes how the player moves, looks and survives. Edited in data/player_tuning.tres; the spec's
## Tuning table maps 1:1 to these fields. The guns' numbers live in their own GunStats (data/rifle.tres,
## data/pistol.tres, recipe 53). Units: metres, seconds, degrees unless marked.

@export_group("Move")
@export var walk_speed := 5.0                 ## m/s
@export var sprint_speed := 7.5               ## m/s — no firing while sprinting; sprint cancels a reload
@export var crouch_speed := 2.6               ## m/s
@export var acceleration := 45.0              ## m/s²
@export var friction := 55.0                  ## m/s²
@export_range(0.0, 1.0) var air_control := 0.4
@export var jump_height := 1.0                ## m
@export var time_to_apex := 0.32              ## s
@export var stand_eye := 1.6                  ## m — camera height standing
@export var crouch_eye := 0.95                ## m — below low cover (1.1 m)
@export var crouch_time := 0.15               ## s to go down or up
@export var sprint_to_fire := 0.2             ## s after sprinting before the gun can fire (raising it)

@export_group("Look")
@export var fov := 90.0                       ## degrees, vertical-ish (Camera3D.fov); PC default 90–100
@export var ads_fov_scale := 0.72             ## FOV × this while fully aiming
@export var mouse_sensitivity := 0.0022       ## rad per pixel (screen_relative)
@export var ads_sensitivity_scale := 0.7      ## look speed × this while fully aiming
@export var stick_look_speed := 3.2           ## rad/s at full right-stick deflection
@export_range(-89.0, 0.0) var min_pitch_deg := -85.0
@export_range(0.0, 89.0) var max_pitch_deg := 85.0
@export var aim_assist := true                ## slowdown + pull, for pads only (recipe 56)

@export_group("Health")
@export var max_health := 100.0
@export var regen_delay := 4.0                ## s after the last hit (recipe 55)
@export var regen_rate := 40.0                ## health per second
@export var danger_below := 0.4               ## fraction of health where the red edges start

@export_group("Weapons")
@export var primary: GunStats
@export var secondary: GunStats
@export var suppress_radius := 2.0            ## m — a shot landing this close to a soldier suppresses it
@export var swap_time := 0.4                  ## s — switching guns
