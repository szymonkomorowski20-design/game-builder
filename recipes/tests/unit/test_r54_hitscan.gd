extends GutTest
## Recipe 54 — hitscan with hit zones: shot directions from spread offsets, zones read from the shape that was hit,
## walls block, the shooter can exclude itself, damage by zone through recipe 53.


func _target(at: Vector3) -> CharacterBody3D:
	var t := CharacterBody3D.new()
	var body := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.4
	body.shape = capsule
	body.position = Vector3(0, 0.9, 0)
	body.set_meta(&"hit_zone", &"body")
	t.add_child(body)
	var head := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.22
	head.shape = sphere
	head.position = Vector3(0, 1.75, 0)
	head.set_meta(&"hit_zone", &"head")
	t.add_child(head)
	add_child_autofree(t)
	t.global_position = at
	return t


func _wall(at: Vector3) -> StaticBody3D:
	var w := StaticBody3D.new()
	var s := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 4, 0.3)
	s.shape = box
	w.add_child(s)
	add_child_autofree(w)
	w.global_position = at
	return w


func test_r54_shot_direction_bends_forward_by_the_offset() -> void:
	var b := Basis()
	assert_almost_eq(Hitscan.shot_direction(b, Vector2.ZERO), Vector3(0, 0, -1), Vector3.ONE * 1e-5, "no offset: straight ahead")
	assert_almost_eq(Hitscan.shot_direction(b, Vector2(90, 0)), Vector3(1, 0, 0), Vector3.ONE * 1e-5, "+yaw turns right")
	assert_almost_eq(Hitscan.shot_direction(b, Vector2(0, 90)), Vector3(0, 1, 0), Vector3.ONE * 1e-5, "+pitch turns up")
	var turned := Basis(Vector3.UP, PI * 0.5)     # looking along −X
	assert_almost_eq(Hitscan.shot_direction(turned, Vector2(90, 0)), Vector3(0, 0, -1), Vector3.ONE * 1e-5, "offsets follow the camera's own axes")


func test_r54_zones_walls_and_self() -> void:
	var t := _target(Vector3(0, 0, -10))
	await wait_physics_frames(2)
	var world := get_tree().root.get_world_3d()
	var head := Hitscan.cast(world, Vector3(0, 1.75, 0), Vector3(0, 0, -1), 100.0)
	assert_eq(head.get("collider"), t, "the target is hit")
	assert_eq(head.get("zone"), &"head", "at head height: the head zone")
	var body := Hitscan.cast(world, Vector3(0, 1.0, 0), Vector3(0, 0, -1), 100.0)
	assert_eq(body.get("zone"), &"body", "at chest height: the body zone")
	assert_almost_eq(float(body.get("distance")), 9.6, 0.05, "distance to the capsule's surface")
	assert_true(Hitscan.cast(world, Vector3(0, 1.0, 0), Vector3(0, 0, -1), 5.0).is_empty(), "out of range: nothing")
	var w := _wall(Vector3(0, 1, -5))
	await wait_physics_frames(2)
	assert_eq(Hitscan.cast(world, Vector3(0, 1.75, 0), Vector3(0, 0, -1), 100.0).get("collider"), w, "a wall in between takes the shot")
	var excluded: Array[RID] = [w.get_rid()]
	assert_eq(Hitscan.cast(world, Vector3(0, 1.75, 0), Vector3(0, 0, -1), 100.0, 0xFFFFFFFF, excluded).get("collider"), t, "excluded bodies are shot through (the shooter's own)")


func test_r54_zone_damage_through_the_gun() -> void:
	var t := _target(Vector3(0, 0, -10))
	await wait_physics_frames(2)
	var world := get_tree().root.get_world_3d()
	var gun := GunModel.new(GunStats.new(), 1)
	var hit := Hitscan.cast(world, Vector3(0, 1.75, 0), Vector3(0, 0, -1), 100.0)
	var dmg := gun.damage_at(float(hit.distance), hit.zone)
	assert_almost_eq(dmg, gun.stats.damage * gun.stats.headshot_mult, 1e-4, "a headshot at 10 m: full damage × headshot")
	assert_eq(t.name.is_empty(), false)
