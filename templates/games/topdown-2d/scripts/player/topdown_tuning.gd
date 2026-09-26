class_name TopDownTuning
extends Resource
## Every feel/balance number of the top-down template. Edit data/topdown_tuning.tres, not the scripts.

@export_group("Movement")
@export var move_speed: float = 150.0        ## px/s
@export var acceleration: float = 1200.0     ## px/s²
@export var friction: float = 1500.0         ## px/s²

@export_group("Shooting")
@export var shoot_cooldown: float = 0.25     ## s between shots
@export var bullet_speed: float = 420.0      ## px/s
@export var bullet_damage: int = 1
@export var bullet_lifetime: float = 1.2     ## s

@export_group("Health")
@export var max_health: int = 5
@export var invulnerability: float = 0.8     ## s after being hit
