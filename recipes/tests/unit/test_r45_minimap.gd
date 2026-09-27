extends GutTest
## R45 — world → minimap mapping: uniform scale that keeps the aspect, centred; corners map to the used area's
## corners; points outside the world are pinned to the edge.

const WORLD := Rect2(0, 0, 640, 360)       # 16:9
const MAP := Vector2(150, 100)             # wider than 16:9 → letterboxed left/right


func test_r45_corners_and_centre() -> void:
	# scale = min(150/640, 100/360) = 0.27778 → used 177.8×100? no: 640×0.27778 = 177.8 > 150, so scale = 150/640
	var scale := minf(MAP.x / WORLD.size.x, MAP.y / WORLD.size.y)
	var used := WORLD.size * scale
	var offset := (MAP - used) / 2.0
	assert_true(Minimap.map_point(Vector2(0, 0), WORLD, MAP).is_equal_approx(offset), "top-left corner")
	assert_true(Minimap.map_point(Vector2(640, 360), WORLD, MAP).is_equal_approx(offset + used), "bottom-right corner")
	assert_true(Minimap.map_point(Vector2(320, 180), WORLD, MAP).is_equal_approx(MAP / 2.0), "centre → centre")


func test_r45_aspect_is_kept() -> void:
	var a := Minimap.map_point(Vector2(0, 0), WORLD, MAP)
	var b := Minimap.map_point(Vector2(100, 100), WORLD, MAP)
	assert_almost_eq(b.x - a.x, b.y - a.y, 0.0001, "the same world distance on both axes → the same map distance")


func test_r45_outside_is_pinned_to_the_edge() -> void:
	var right_edge := Minimap.map_point(Vector2(640, 180), WORLD, MAP)
	var far := Minimap.map_point(Vector2(5000, 180), WORLD, MAP)
	assert_true(far.is_equal_approx(right_edge), "far to the right → on the right edge, same height")
	var up_left := Minimap.map_point(Vector2(-300, -300), WORLD, MAP)
	assert_true(up_left.is_equal_approx(Minimap.map_point(Vector2(0, 0), WORLD, MAP)), "far up-left → top-left corner")
