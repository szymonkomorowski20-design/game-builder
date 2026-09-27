class_name ShootTarget
extends StaticBody3D
## A target with health. Hits flash it; at 0 it is destroyed (signal, then freed). `sway` > 0 makes it move back and
## forth along X by that many metres (period `sway_period` s) — a moving target to lead.

signal destroyed(target: ShootTarget)

@export var health := 3
@export var sway := 0.0            ## m either side
@export var sway_period := 2.0     ## s for a full back-and-forth

var hits := 0
var _time := 0.0
var _origin := Vector3.ZERO
var _flash := 0.0

@onready var look: MeshInstance3D = $Look


func _ready() -> void:
	_origin = position


func _physics_process(delta: float) -> void:
	_time += delta
	if sway > 0.0:
		position = _origin + Vector3(sin(_time * TAU / sway_period) * sway, 0, 0)
	_flash = maxf(_flash - delta, 0.0)
	look.transparency = 0.5 if _flash > 0.0 else 0.0


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	hits += 1
	health -= amount
	_flash = 0.08
	if health <= 0:
		destroyed.emit(self)
		queue_free()
