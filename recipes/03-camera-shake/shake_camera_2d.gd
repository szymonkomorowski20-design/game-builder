class_name ShakeCamera2D
extends Camera2D
## Trauma-based screen shake: add_trauma() on hits/explosions; shake strength = trauma² (small hits
## barely shake, big ones shake hard); trauma decays linearly. Noise (not randf) keeps it smooth.

@export var decay: float = 1.5                          ## trauma per second
@export var max_offset: Vector2 = Vector2(16.0, 10.0)   ## px at trauma 1
@export var max_roll: float = 0.05                      ## rad at trauma 1

var trauma: float = 0.0
var _noise := FastNoiseLite.new()
var _t: float = 0.0


func _ready() -> void:
	_noise.seed = 1
	_noise.frequency = 8.0


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	advance(delta)


## Separate from _process so tests can drive it deterministically.
func advance(delta: float) -> void:
	_t += delta
	trauma = maxf(trauma - decay * delta, 0.0)
	var s := trauma * trauma
	offset = Vector2(max_offset.x * s * _noise.get_noise_2d(_t * 100.0, 0.0), max_offset.y * s * _noise.get_noise_2d(0.0, _t * 100.0))
	rotation = max_roll * s * _noise.get_noise_2d(_t * 100.0, 50.0)
