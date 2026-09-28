class_name RtsLook
extends RefCounted
## The template's placeholder look, built from primitives (swap for models: keep the node names and sizes). Units are
## told apart by silhouette and size first (genre doc §9): a small worker with a round head, a broad footman with a
## shield, a thin archer with a tall bow, a long rider. Team colour is the body; resources are gold crystals and trees.

const TEAMS: Array[Color] = [Color(0.2, 0.45, 0.95), Color(0.9, 0.22, 0.18), Color(0.3, 0.8, 0.35), Color(0.95, 0.8, 0.2)]

static var _mats := {}


static func team_colour(t: int) -> Color:
	return TEAMS[clampi(t, 0, TEAMS.size() - 1)]


static func mat(c: Color, unshaded: bool = false) -> StandardMaterial3D:
	var key := "%s%s" % [c.to_html(), unshaded]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mats[key] = m
	return m


static func _part(parent: Node3D, mesh: Mesh, at: Vector3, c: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = at
	m.material_override = mat(c)
	parent.add_child(m)
	return m


static func unit_body(kind: StringName, r: float, team: Color) -> MeshInstance3D:
	var root := MeshInstance3D.new()
	root.name = "Body"
	var body := CapsuleMesh.new()
	body.radius = r * 0.8
	body.height = 1.1 if kind == &"worker" else 1.5
	root.mesh = body
	root.position.y = body.height * 0.5
	root.material_override = mat(team)
	var skin := Color(0.95, 0.8, 0.65)
	match kind:
		&"worker":
			var head := SphereMesh.new()
			head.radius = 0.18
			head.height = 0.36
			_part(root, head, Vector3(0, 0.62, 0), skin)
			var tool := BoxMesh.new()
			tool.size = Vector3(0.08, 0.6, 0.08)
			_part(root, tool, Vector3(0.3, 0.1, -0.1), Color(0.45, 0.3, 0.15))
		&"footman":
			var shield := BoxMesh.new()
			shield.size = Vector3(0.55, 0.7, 0.1)
			_part(root, shield, Vector3(-0.1, 0.05, -0.38), Color(0.75, 0.75, 0.8))
			var helm := SphereMesh.new()
			helm.radius = 0.22
			helm.height = 0.3
			_part(root, helm, Vector3(0, 0.85, 0), Color(0.6, 0.6, 0.65))
		&"archer":
			var bow := BoxMesh.new()
			bow.size = Vector3(0.06, 1.3, 0.06)
			_part(root, bow, Vector3(0.32, 0.2, -0.15), Color(0.5, 0.33, 0.15))
			var hood := SphereMesh.new()
			hood.radius = 0.18
			hood.height = 0.4
			_part(root, hood, Vector3(0, 0.82, 0), Color(0.2, 0.4, 0.2))
		&"rider":
			var horse := BoxMesh.new()
			horse.size = Vector3(0.5, 0.55, 1.4)
			_part(root, horse, Vector3(0, -0.45, 0), Color(0.45, 0.3, 0.2))
			var lance := BoxMesh.new()
			lance.size = Vector3(0.06, 0.06, 1.6)
			_part(root, lance, Vector3(0.3, 0.2, -0.6), Color(0.8, 0.8, 0.8))
	return root


static func building_body(kind: StringName, footprint: Vector2, team: Color) -> MeshInstance3D:
	var root := MeshInstance3D.new()
	root.name = "Body"
	var h := {&"town_hall": 3.2, &"farm": 1.2, &"barracks": 2.4, &"stable": 2.0}.get(kind, 2.0) as float
	var box := BoxMesh.new()
	box.size = Vector3(footprint.x, h, footprint.y)
	_part(root, box, Vector3(0, h * 0.5, 0), Color(0.72, 0.66, 0.55))      # the walls (child 0: pale while a site)
	var roof := PrismMesh.new()
	roof.size = Vector3(footprint.x + 0.2, h * 0.5, footprint.y + 0.2)
	_part(root, roof, Vector3(0, h + h * 0.25, 0), team)
	if kind == &"farm":
		var field := BoxMesh.new()
		field.size = Vector3(footprint.x * 0.9, 0.1, footprint.y * 0.4)
		_part(root, field, Vector3(0, 0.05, footprint.y * 0.55), Color(0.85, 0.75, 0.3))
	return root


## A site is drawn pale until finished.
static func set_site(body: MeshInstance3D, site: bool) -> void:
	for c in body.get_children():
		var m := c as MeshInstance3D
		if m != null and m.get_index() == 0:
			m.transparency = 0.45 if site else 0.0


static func resource_body(res: StringName, r: float) -> MeshInstance3D:
	var root := MeshInstance3D.new()
	root.name = "Body"
	if res == &"gold":
		var rock := CylinderMesh.new()
		rock.top_radius = r * 0.7
		rock.bottom_radius = r
		rock.height = 1.2
		var base := _part(root, rock, Vector3(0, 0.6, 0), Color(0.45, 0.42, 0.4))
		base.name = "Rock"
		for i in 3:
			var crystal := PrismMesh.new()
			crystal.size = Vector3(0.4, 0.9, 0.4)
			_part(root, crystal, Vector3(cos(i * 2.1) * r * 0.4, 1.5, sin(i * 2.1) * r * 0.4), Color(1.0, 0.82, 0.2))
	else:
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.15
		trunk.bottom_radius = 0.2
		trunk.height = 1.2
		_part(root, trunk, Vector3(0, 0.6, 0), Color(0.4, 0.28, 0.15))
		var crown := CylinderMesh.new()
		crown.top_radius = 0.0
		crown.bottom_radius = r
		crown.height = 2.2
		_part(root, crown, Vector3(0, 2.1, 0), Color(0.18, 0.45, 0.2))
	return root
