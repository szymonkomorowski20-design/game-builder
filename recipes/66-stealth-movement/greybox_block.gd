class_name GreyboxBlock
extends RefCounted
## A coloured, collidable box for demos and blockouts (recipes 66–67 and the stealth template). `layers` lets a level
## put climbable geometry on its own physics layer (recipe 67) apart from plain walls; `groups` marks e.g. a hay pile
## as `soft_landing` (recipe 66).


static func make(centre: Vector3, size: Vector3, colour: Color, layers := 1,
		groups: Array[StringName] = []) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layers
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	box_mesh.material = material
	mesh.mesh = box_mesh
	body.add_child(mesh)
	body.position = centre
	for g in groups:
		body.add_to_group(g)
	return body
