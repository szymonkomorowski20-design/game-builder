class_name AsciiLevel
extends RefCounted
## Builds a TileMapLayer from text rows — handy for tests, level prototypes and procedural output (recipe 28):
##   "#" wall (solid)   "~" lava (custom data hazard=true)   "." floor   " " empty
## and answers gameplay questions in world coordinates (is this position hazardous? is it solid?).

const TILE := 16
const ATLAS := {"#": Vector2i(0, 0), "~": Vector2i(1, 0), ".": Vector2i(2, 0)}


## A TileSet made in code: 3 tiles, a physics layer (walls collide), custom data layer "hazard".
## In a real game build the TileSet in the editor from your tileset image — the API below stays the same.
static func make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "hazard")
	ts.set_custom_data_layer_type(0, TYPE_BOOL)
	var img := Image.create(TILE * 3, TILE, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(0, 0, TILE, TILE), Color(0.35, 0.35, 0.4))
	img.fill_rect(Rect2i(TILE, 0, TILE, TILE), Color(0.9, 0.35, 0.1))
	img.fill_rect(Rect2i(TILE * 2, 0, TILE, TILE), Color(0.15, 0.15, 0.18))
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	for coords in ATLAS.values():
		src.create_tile(coords)
	var wall := src.get_tile_data(ATLAS["#"], 0)
	var h := TILE / 2.0
	wall.add_collision_polygon(0)
	wall.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)]))
	src.get_tile_data(ATLAS["~"], 0).set_custom_data("hazard", true)
	return ts


static func build(rows: PackedStringArray, layer: TileMapLayer = null) -> TileMapLayer:
	if layer == null:
		layer = TileMapLayer.new()
	if layer.tile_set == null:
		layer.tile_set = make_tileset()
	layer.clear()
	for y in rows.size():
		for x in rows[y].length():
			var ch := rows[y][x]
			if ATLAS.has(ch):
				layer.set_cell(Vector2i(x, y), 0, ATLAS[ch])
	return layer


static func is_hazard(layer: TileMapLayer, world_pos: Vector2) -> bool:
	var data := layer.get_cell_tile_data(layer.local_to_map(layer.to_local(world_pos)))
	return data != null and bool(data.get_custom_data("hazard"))


static func is_solid(layer: TileMapLayer, world_pos: Vector2) -> bool:
	var data := layer.get_cell_tile_data(layer.local_to_map(layer.to_local(world_pos)))
	return data != null and data.get_collision_polygons_count(0) > 0
