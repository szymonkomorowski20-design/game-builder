class_name RtsMine
extends StaticBody3D
## A resource on the map: a gold mine or a tree (recipe 59's RtsResourceNode inside). Workers stand at its edge;
## spent, it disappears and frees its cells.
## Observable: node (kind, amount, gathering).

var node: RtsResourceNode
var team := -1
var kind: StringName = &""
var is_resource := true
var is_building := false
var alive := true
var game: RtsGame
var cells: Array[Vector2i] = []
var radius := 1.0


func setup(g: RtsGame, res: StringName, amount: int, slots: int, r: float) -> void:
	game = g
	kind = res
	radius = r
	node = RtsResourceNode.new(res, amount, slots, global_position)
	node.depleted.connect(_on_depleted)
	collision_layer = 1
	collision_mask = 0
	add_to_group(&"mines")
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = r
	cyl.height = 2.0
	shape.shape = cyl
	shape.position.y = 1.0
	add_child(shape)
	add_child(RtsLook.resource_body(res, r))


func extent() -> float:
	return radius


func edge_distance(p: Vector3) -> float:
	return maxf(Vector2(p.x - global_position.x, p.z - global_position.z).length() - radius, 0.0)


func armour() -> Dictionary:
	return {"armour": 0.0, "armour_type": &"fortified", "tags": []}


func _on_depleted() -> void:
	alive = false
	game.on_mine_spent(self)
	queue_free()
