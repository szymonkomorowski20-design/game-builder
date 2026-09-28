class_name RtsMap
extends RefCounted
## The skirmish map, built in code (72 × 72 m): two bases in opposite corners — the player's at the bottom left, the
## computer's at the top right, mirrored so neither side has a better start — each with two gold mines and a line of
## trees behind it, and rocks in the middle that split the way into lanes. Everything that blocks building goes into
## the grid, and the navigation mesh is baked from the static colliders (ground, rocks, mines, trees, buildings).
## Swap the look for models by editing RtsLook; keep the layout's offsets mirrored.

const HALF := 36.0
const BASE := Vector3(-22, 0, 22)                  ## the player's base; the computer's is its mirror
## Relative to a base (mirrored for the other team): gold mines and the tree line.
const GOLD := [Vector3(-10, 0, -5), Vector3(5, 0, 10)]
const TREES := [
	Vector3(-12, 0, 0), Vector3(-12, 0, 2.5), Vector3(-12, 0, 5), Vector3(-12, 0, 7.5), Vector3(-11, 0, 10), Vector3(-9, 0, 12),
	Vector3(-6.5, 0, 12.5), Vector3(-4, 0, 13), Vector3(-13.5, 0, 3.7), Vector3(-13.5, 0, 8.7), Vector3(-10.5, 0, 12.8), Vector3(-2, 0, 13.5),
]
const ROCKS := [
	[Vector3(0, 0, 0), Vector3(6, 3, 6)],
	[Vector3(-11, 0, -9), Vector3(4, 3, 5)],
	[Vector3(11, 0, 9), Vector3(4, 3, 5)],
]


static func build(g: RtsGame) -> NavigationRegion3D:
	var nav := NavigationRegion3D.new()
	nav.name = "Navigation"
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.agent_radius = 0.75                         # a multiple of the cell (0.6 is ceiled to 0.75 anyway, with a warning GUT counts)
	nm.agent_height = 1.5
	nm.agent_max_climb = 0.25                      # a multiple of the cell height (0.3 is floored to 0.25, with a warning)
	nav.navigation_mesh = nm
	g.world_root.add_child(nav)
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	ground.collision_layer = 1
	var gs := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(HALF * 2.0, 1.0, HALF * 2.0)
	gs.shape = gb
	gs.position.y = -0.5
	ground.add_child(gs)
	var gm := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(HALF * 2.0, HALF * 2.0)
	gm.mesh = plane
	gm.material_override = RtsLook.mat(Color(0.36, 0.5, 0.28))
	ground.add_child(gm)
	nav.add_child(ground)
	var beyond := MeshInstance3D.new()                # what the camera sees past the map's edge
	var far := PlaneMesh.new()
	far.size = Vector2(400, 400)
	beyond.mesh = far
	beyond.position.y = -0.3
	beyond.material_override = RtsLook.mat(Color(0.08, 0.09, 0.07))
	g.world_root.add_child(beyond)
	for r in ROCKS:
		_rock(g, nav, r[0], r[1])
	g.bases = [BASE, -BASE]
	for t in 2:
		var sign_ := 1.0 if t == 0 else -1.0
		var base := BASE * sign_
		for off: Vector3 in GOLD:
			_mine(g, nav, base + off * sign_, &"gold", 1.6)
		for off: Vector3 in TREES:
			_mine(g, nav, base + off * sign_, &"wood", 0.9)
	# The map's rim: no building on the outermost cells.
	for i in g.grid.width:
		for c: Vector2i in [Vector2i(i, 0), Vector2i(i, g.grid.height - 1), Vector2i(0, i), Vector2i(g.grid.width - 1, i)]:
			g.grid.blocked[c] = true
	return nav


static func _rock(g: RtsGame, nav: Node3D, at: Vector3, size: Vector3) -> void:
	var b := StaticBody3D.new()
	b.name = "Rock%d" % nav.get_child_count()
	b.position = at
	b.collision_layer = 1
	var s := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	s.shape = box
	s.position.y = size.y * 0.5
	b.add_child(s)
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.position.y = size.y * 0.5
	m.material_override = RtsLook.mat(Color(0.5, 0.48, 0.45))
	b.add_child(m)
	nav.add_child(b)
	g.props.append(b)
	var c0 := g.grid.cell_of(at - size * 0.5)
	var c1 := g.grid.cell_of(at + size * 0.5)
	for y in range(c0.y, c1.y + 1):
		for x in range(c0.x, c1.x + 1):
			g.grid.blocked[Vector2i(x, y)] = true


static func _mine(g: RtsGame, nav: Node3D, at: Vector3, res: StringName, r: float) -> void:
	var m := RtsMine.new()
	m.name = "%s_%d" % [res, g.mines.size()]
	m.position = at
	nav.add_child(m)
	var spec: Dictionary = g.rules.resources[res]
	m.setup(g, res, int(spec.amount), int(spec.slots), r)
	g.mines.append(m)
	# Cells under it, plus a ring for gold (the genre keeps town halls off their mines).
	var ring := 2 if res == &"gold" else 0
	var c := g.grid.cell_of(at)
	for y in range(c.y - 1 - ring, c.y + 1 + ring):
		for x in range(c.x - 1 - ring, c.x + 1 + ring):
			var cell := Vector2i(x, y)
			if not g.grid.blocked.has(cell):
				m.cells.append(cell)
			g.grid.blocked[cell] = true
