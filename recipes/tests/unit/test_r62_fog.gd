extends GutTest
## R62 — fog of war. A viewer reveals a circle (inside visible, outside not); what it leaves stays explored but not
## visible; overlapping viewers; the map's edge; the overlay image's three values; reveal_all; and the cost: 200
## viewers on a 128×128 grid update in a few milliseconds.


func test_r62_a_viewer_reveals_a_circle() -> void:
	var f := RtsFog.new(64, 64, 1.0)
	f.update([{"at": Vector3(20, 0, 20), "sight": 5.0}])
	assert_true(f.is_visible(Vector3(20, 0, 20)))
	assert_true(f.is_visible(Vector3(24.5, 0, 20.5)), "4.5 m away: inside")
	assert_false(f.is_visible(Vector3(27, 0, 20)), "7 m away: outside")
	assert_false(f.is_visible(Vector3(24, 0, 24)), "the corner of the square is not in the circle")
	assert_false(f.is_explored(Vector3(40, 0, 40)), "far away: never seen")


func test_r62_what_it_leaves_stays_explored() -> void:
	var f := RtsFog.new(64, 64, 1.0)
	f.update([{"at": Vector3(10, 0, 10), "sight": 4.0}])
	f.update([{"at": Vector3(40, 0, 10), "sight": 4.0}])
	assert_eq(f.state_at(Vector3(10, 0, 10)), RtsFog.EXPLORED, "seen once: explored, not visible")
	assert_eq(f.state_at(Vector3(40, 0, 10)), RtsFog.VISIBLE)
	assert_eq(f.state_at(Vector3(25, 0, 10)), RtsFog.UNEXPLORED)


func test_r62_overlaps_and_edges() -> void:
	var f := RtsFog.new(32, 32, 2.0, Vector3(-32, 0, -32))
	f.update([{"at": Vector3(-31, 0, -31), "sight": 8.0}, {"at": Vector3(-26, 0, -31), "sight": 8.0}])
	assert_true(f.is_visible(Vector3(-31, 0, -31)), "a viewer at the map's corner")
	assert_true(f.is_visible(Vector3(-20, 0, -31)), "the second viewer's circle")
	assert_false(f.is_visible(Vector3(-40, 0, -31)), "off the map is never visible")


func test_r62_the_overlay_image() -> void:
	var f := RtsFog.new(16, 16, 1.0)
	f.update([{"at": Vector3(2, 0, 2), "sight": 1.0}])
	f.update([{"at": Vector3(12, 0, 12), "sight": 1.0}])
	var img := f.to_image()
	assert_eq(img.get_format(), Image.FORMAT_L8)
	assert_almost_eq(img.get_pixel(12, 12).r, 1.0, 0.01, "visible: white")
	assert_almost_eq(img.get_pixel(2, 2).r, 128.0 / 255.0, 0.01, "explored: grey")
	assert_almost_eq(img.get_pixel(7, 7).r, 0.0, 0.01, "unexplored: black")
	f.reveal_all()
	assert_almost_eq(f.explored_fraction(), 1.0, 0.0001)


func test_r62_two_hundred_viewers_update_quickly() -> void:
	var f := RtsFog.new(128, 128, 1.0)
	var viewers: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 200:
		viewers.append({"at": Vector3(rng.randf_range(0, 128), 0, rng.randf_range(0, 128)), "sight": rng.randf_range(6.0, 10.0)})
	f.update(viewers)           # warm the circle cache
	var t := Time.get_ticks_usec()
	for i in 5:
		f.update(viewers)
	var ms := (Time.get_ticks_usec() - t) / 5000.0
	gut.p("200 viewers, 128×128: %.2f ms per update" % ms)
	assert_lt(ms, 25.0, "a few updates a second fit easily (%.2f ms)" % ms)
