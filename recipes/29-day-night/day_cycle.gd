class_name DayCycle
extends Node
## Time of day 0..1 (0 = midnight, 0.25 = 06:00, 0.5 = noon). Emits phase changes once per transition and tints a
## CanvasModulate (2D) — for 3D drive a DirectionalLight3D rotation and WorldEnvironment the same way.

signal phase_changed(phase: StringName)
signal new_day(day: int)

@export var day_length := 240.0            ## real seconds per in-game day
@export var time := 0.3                    ## start at ~07:12
@export var tint: CanvasModulate
@export var colors: Gradient

var day := 1
var phase: StringName = &""


func _ready() -> void:
	if colors == null:
		colors = Gradient.new()
		colors.offsets = PackedFloat32Array([0.0, 0.22, 0.3, 0.5, 0.72, 0.8, 1.0])
		colors.colors = PackedColorArray([
			Color(0.2, 0.22, 0.4), Color(0.2, 0.22, 0.4), Color(1.0, 0.75, 0.6), Color(1, 1, 1),
			Color(1.0, 0.7, 0.5), Color(0.2, 0.22, 0.4), Color(0.2, 0.22, 0.4)])
	phase = phase_at(time)
	_apply()


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	time += delta / day_length
	while time >= 1.0:
		time -= 1.0
		day += 1
		new_day.emit(day)
	var p := phase_at(time)
	if p != phase:
		phase = p
		phase_changed.emit(p)
	_apply()


static func phase_at(t: float) -> StringName:
	if t < 0.22:
		return &"night"
	if t < 0.3:
		return &"dawn"
	if t < 0.72:
		return &"day"
	if t < 0.8:
		return &"dusk"
	return &"night"


func light_color() -> Color:
	return colors.sample(time) if colors != null else Color.WHITE


func clock() -> String:
	var minutes := int(time * 24.0 * 60.0)
	return "%02d:%02d" % [minutes / 60, minutes % 60]


func _apply() -> void:
	if tint != null:
		tint.color = light_color()
