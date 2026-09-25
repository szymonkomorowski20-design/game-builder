extends GutTest
## R03 — trauma accumulates, clamps at 1, decays; no trauma → no offset.


func _cam() -> ShakeCamera2D:
	var c := ShakeCamera2D.new()
	add_child_autofree(c)
	return c


func test_r03_trauma_clamps_at_one() -> void:
	var c := _cam()
	c.add_trauma(0.7)
	c.add_trauma(0.7)
	assert_eq(c.trauma, 1.0)


func test_r03_trauma_decays_linearly() -> void:
	var c := _cam()
	c.add_trauma(0.9)
	c.advance(0.2)
	assert_almost_eq(c.trauma, 0.9 - c.decay * 0.2, 0.0001)
	c.advance(10.0)
	assert_eq(c.trauma, 0.0)


func test_r03_no_trauma_no_offset() -> void:
	var c := _cam()
	c.advance(0.016)
	assert_eq(c.offset, Vector2.ZERO)
	assert_eq(c.rotation, 0.0)


func test_r03_offset_bounded_by_max() -> void:
	var c := _cam()
	for i in 30:
		c.trauma = 1.0
		c.advance(0.016)
		assert_true(absf(c.offset.x) <= c.max_offset.x + 0.001 and absf(c.offset.y) <= c.max_offset.y + 0.001)
