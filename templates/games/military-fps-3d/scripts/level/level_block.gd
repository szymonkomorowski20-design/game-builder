@tool
class_name LevelBlock
extends StaticBody3D
## One box of level geometry: a wall, a crate, a floor. It builds its own mesh and collision from `size`, so the level
## scene lists only a transform, a size and a colour per block, and the navigation mesh is baked from these colliders
## at runtime (mission.gd). Low cover is `size.y` ≈ 1.1 m: it hides a crouched body (eye 0.9–1.0 m) and a standing
## one can shoot over it.

@export var size := Vector3(2, 1.1, 0.6):
	set(v):
		size = v
		_build()
@export var color := Color(0.42, 0.4, 0.36):
	set(v):
		color = v
		_build()

var _mesh: MeshInstance3D
var _shape: CollisionShape3D


func _ready() -> void:
	_build()


func _build() -> void:
	if not is_inside_tree():
		return
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.name = "Mesh"
		add_child(_mesh, false, Node.INTERNAL_MODE_FRONT)
		_shape = CollisionShape3D.new()
		_shape.name = "Shape"
		add_child(_shape, false, Node.INTERNAL_MODE_FRONT)
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	box.material = mat
	_mesh.mesh = box
	var shape := BoxShape3D.new()
	shape.size = size
	_shape.shape = shape
