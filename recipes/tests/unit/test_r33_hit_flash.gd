extends GutTest
## R33 — flash jumps to 1 and decays to 0 over the duration; two targets have independent materials.


func _sprite() -> Polygon2D:
	var s := Polygon2D.new()
	s.polygon = PackedVector2Array([Vector2(0, 0), Vector2(8, 0), Vector2(8, 8)])
	var f := HitFlash.new()
	f.name = "HitFlash"
	f.duration = 0.1
	s.add_child(f)
	add_child_autofree(s)
	return s


func test_r33_flash_decays() -> void:
	var f := _sprite().get_node("HitFlash") as HitFlash
	f.flash()
	assert_almost_eq(f.amount(), 1.0, 0.001)
	await wait_seconds(0.25)
	assert_almost_eq(f.amount(), 0.0, 0.001)


func test_r33_materials_are_independent() -> void:
	var a := _sprite()
	var b := _sprite()
	assert_ne(a.material, b.material)
	(a.get_node("HitFlash") as HitFlash).flash()
	assert_almost_eq((b.get_node("HitFlash") as HitFlash).amount(), 0.0, 0.001, "b did not flash")
