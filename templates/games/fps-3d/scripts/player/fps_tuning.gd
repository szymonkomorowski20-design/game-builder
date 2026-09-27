class_name FpsTuning
extends Resource
## Every number that shapes how the shooter feels. Edited in data/fps_tuning.tres — the spec's Tuning table maps 1:1
## to these fields. Units: metres, seconds, radians.

@export_group("Move")
@export var walk_speed: float = 6.0           ## m/s
@export var acceleration: float = 50.0        ## m/s²
@export var friction: float = 60.0            ## m/s²
@export_range(0.0, 1.0) var air_control: float = 0.5
@export var jump_height: float = 1.2          ## m
@export var time_to_apex: float = 0.35        ## s

@export_group("Look")
@export var mouse_sensitivity: float = 0.0025 ## rad per pixel (screen_relative)
@export var stick_look_speed: float = 3.0     ## rad/s at full right-stick deflection
@export_range(-89.0, 0.0) var min_pitch_deg: float = -85.0
@export_range(0.0, 89.0) var max_pitch_deg: float = 85.0

@export_group("Weapon")
@export var fire_interval: float = 0.15       ## s between shots while shoot is held (≈ 6.7 shots/s)
@export var damage: int = 1                   ## health points per hit
@export var weapon_range: float = 60.0        ## m
