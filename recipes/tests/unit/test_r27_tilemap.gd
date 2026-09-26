extends GutTest
## R27 — ASCII rows become cells, world ↔ cell conversion (including an offset layer), custom data and collision per tile.

const ROWS := ["#####", "#..~#", "#####"]


func _layer() -> TileMapLayer:
	var l := AsciiLevel.build(PackedStringArray(ROWS))
	add_child_autofree(l)
	return l


func test_r27_cells_from_rows() -> void:
	var l := _layer()
	assert_eq(l.get_used_rect(), Rect2i(0, 0, 5, 3))
	assert_eq(l.get_cell_atlas_coords(Vector2i(3, 1)), Vector2i(1, 0), "lava tile")
	assert_eq(l.get_used_cells().size(), 15)


func test_r27_hazard_and_solid_in_world_coordinates() -> void:
	var l := _layer()
	assert_true(AsciiLevel.is_hazard(l, Vector2(3 * 16 + 8, 16 + 8)), "centre of the lava cell")
	assert_false(AsciiLevel.is_hazard(l, Vector2(1 * 16 + 8, 16 + 8)), "floor")
	assert_true(AsciiLevel.is_solid(l, Vector2(4, 4)), "wall corner")
	assert_false(AsciiLevel.is_solid(l, Vector2(2 * 16 + 8, 16 + 8)))
	assert_false(AsciiLevel.is_hazard(l, Vector2(-50, -50)), "outside the map is not hazardous")


func test_r27_offset_layer_converts_through_to_local() -> void:
	var l := _layer()
	l.position = Vector2(100, 50)
	assert_true(AsciiLevel.is_hazard(l, Vector2(100 + 3 * 16 + 8, 50 + 16 + 8)))
	assert_false(AsciiLevel.is_hazard(l, Vector2(3 * 16 + 8, 16 + 8)), "the unshifted position is now outside")
