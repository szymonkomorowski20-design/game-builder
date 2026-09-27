class_name MovingPlatform
extends AnimatableBody2D
## A platform that carries characters standing on it. It must be an AnimatableBody2D moved in _physics_process
## (with sync_to_physics on): CharacterBody2D.move_and_slide() then gets the platform's velocity. A StaticBody2D
## moved by setting `position` teleports under the rider instead — the rider stays behind (and falls off).

@export var waypoints: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2(160, 0)])  ## relative to the start
@export var speed := 80.0   ## px/s

var time := 0.0
var path: PlatformPath
var _origin := Vector2.ZERO


func _ready() -> void:
	sync_to_physics = true
	_origin = position
	path = PlatformPath.new(waypoints, speed)


func _physics_process(delta: float) -> void:
	time += delta
	position = _origin + path.position_at(time)
