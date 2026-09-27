class_name Minimap
extends Control
## A 2D minimap: the level's `world_rect` scaled uniformly into this control (aspect kept, centred) and a dot for
## every node in the tracked groups. Things outside the world rect are pinned to the map's edge, so the player still
## sees the direction. Drawn with _draw — no second viewport, no second copy of the level.
## Observable: `points` (node name → dot position) after each redraw.

@export var world_rect := Rect2(0, 0, 1280, 720)   ## the level area in world pixels
@export var groups := {
	&"minimap_player": Color(0.45, 0.8, 1.0),
	&"minimap_enemy": Color(1.0, 0.4, 0.35),
	&"minimap_pickup": Color(1.0, 0.85, 0.3),
}
@export var dot_radius := 3.0
@export var background := Color(0.08, 0.09, 0.12, 0.8)

var points := {}


func _process(_delta: float) -> void:
	queue_redraw()


## World position → position inside this control (clamped to the map area, inset by the dot radius so a pinned
## dot stays fully inside the map).
func world_to_map(world: Vector2) -> Vector2:
	return map_point(world, world_rect, size, dot_radius)


static func map_point(world: Vector2, rect: Rect2, map_size: Vector2, inset: float = 0.0) -> Vector2:
	var scale := minf(map_size.x / rect.size.x, map_size.y / rect.size.y)
	var used := rect.size * scale
	var offset := (map_size - used) / 2.0
	var p := offset + (world - rect.position) * scale
	return p.clamp(offset + Vector2(inset, inset), offset + used - Vector2(inset, inset))


func _draw() -> void:
	var scale := minf(size.x / world_rect.size.x, size.y / world_rect.size.y)
	var used := world_rect.size * scale
	draw_rect(Rect2((size - used) / 2.0, used), background)
	points.clear()
	for group: StringName in groups:
		for n in get_tree().get_nodes_in_group(group):
			var node2d := n as Node2D
			if node2d == null:
				continue
			var p := world_to_map(node2d.global_position)
			points[node2d.name] = p
			draw_circle(p, dot_radius, groups[group])
