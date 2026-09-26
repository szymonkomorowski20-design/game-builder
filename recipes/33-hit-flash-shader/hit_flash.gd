class_name HitFlash
extends Node
## Flashes a CanvasItem white (or any colour) by driving the `flash` uniform of hit_flash.gdshader.
## Each target gets its OWN ShaderMaterial copy — a shared material would flash every enemy at once.

const SHADER := preload("res://33-hit-flash-shader/hit_flash.gdshader")

@export var target: CanvasItem
@export var duration := 0.15

var _mat: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	if target == null:
		target = get_parent() as CanvasItem
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("flash", 0.0)   # unset uniforms read back as null, not their default
	target.material = _mat


func flash(color: Color = Color.WHITE) -> void:
	_mat.set_shader_parameter("flash_color", color)
	_mat.set_shader_parameter("flash", 1.0)
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(func(v: float): _mat.set_shader_parameter("flash", v), 1.0, 0.0, duration)


func amount() -> float:
	var v = _mat.get_shader_parameter("flash")
	return 0.0 if v == null else float(v)
