class_name Civilian
extends Node3D
## A townsperson (template stealth-parkour-3d): walks recipe 70's lanes (seeded, so the crowd plays the same every run),
## reacts through a CrowdMind (moods only worsen, four phases, a cooldown), steers by slowing rather than turning, and
## may sit on the bench. The game updates it by distance bands (`CrowdRules.lod_due`), with the elapsed time.

const COLOURS := [Color(0.35, 0.45, 0.6), Color(0.55, 0.5, 0.35), Color(0.4, 0.55, 0.4), Color(0.6, 0.4, 0.45),
		Color(0.5, 0.45, 0.55), Color(0.45, 0.35, 0.3)]

var game: StealthGame
var id := 0
var mind := CrowdMind.new()
var rng := RandomNumberGenerator.new()
var walk_speed := 1.25
var seat := -1
var heading := Vector3.FORWARD
var speed := 0.0
var _from := -1
var _to := 0


func setup(p_game: StealthGame, p_id: int, start_point: int) -> void:
	game = p_game
	id = p_id
	name = "Civilian%d" % p_id
	rng.seed = 1000 + p_id
	walk_speed = 1.1 + 0.3 * rng.randf()
	_to = start_point
	position = game.lanes.points[start_point]
	_build_body(COLOURS[p_id % COLOURS.size()])


## Sit on the bench's seat `index` (`at`: its place).
func sit(index: int, at: Vector3) -> void:
	seat = index
	position = at + Vector3(0, -0.25, 0)


func is_calm() -> bool:
	return mind.is_calm()


func tick(delta: float) -> void:
	mind.tick(game.clock, position)
	if seat >= 0:
		if mind.is_calm():
			return
		game.bench.release(self)
		seat = -1
		position.y = 0.0
	var goal: Variant = mind.goal(position)
	var desired: Vector3
	if goal != null:
		desired = (goal as Vector3) - position
	else:
		var p := game.lanes.points[_to]
		if Vector2(p.x - position.x, p.z - position.z).length() < 0.4:
			var n := game.lanes.next_from(_to, _from, rng)
			_from = _to
			_to = n
		desired = game.lanes.points[_to] - position
	var s := CrowdRules.steer(heading, desired, walk_speed * mind.speed_scale(), 4.0, delta)
	heading = s.heading
	speed = s.speed
	position += heading * speed * delta
	position.x = clampf(position.x, -DistrictMap.HALF + 1.0, DistrictMap.HALF - 1.0)
	position.z = clampf(position.z, -DistrictMap.HALF + 1.0, DistrictMap.HALF - 1.0)
	position.y = 0.0
	if heading.length_squared() > 1e-4:
		rotation.y = atan2(-heading.x, -heading.z)


func _build_body(colour: Color) -> void:
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	capsule.material = mat
	mesh.mesh = capsule
	mesh.position.y = 0.85
	add_child(mesh)
