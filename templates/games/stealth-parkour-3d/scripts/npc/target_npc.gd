class_name TargetNpc
extends Node3D
## The contract's target (template stealth-parkour-3d): follows recipe 73's TargetRoutine by the game's clock (the same
## place at the same time, so the player can learn it); alerted, it runs for the palazzo's door; there, it is safe.

signal reached_safety

var game: StealthGame
var routine: TargetRoutine
var alive := true
var alerted := false
var run_speed := 4.0
var safe_at := Vector3.ZERO


func setup(p_game: StealthGame) -> void:
	game = p_game
	name = "Target"
	routine = DistrictMap.routine()
	safe_at = DistrictMap.DOOR
	position = routine.position_at(0.0)
	_build_body()


func tick(delta: float) -> void:
	if not alive:
		return
	var before := position
	if alerted:
		var to := Vector3(safe_at.x - position.x, 0.0, safe_at.z - position.z)
		if to.length() < 0.8:
			alive = false
			visible = false
			reached_safety.emit()
			return
		position += to.normalized() * minf(run_speed * delta, to.length())
	else:
		position = routine.position_at(game.clock)
	var moved := position - before
	if Vector2(moved.x, moved.z).length() > 1e-4:
		rotation.y = atan2(-moved.x, -moved.z)


func kill() -> void:
	alive = false
	var body := get_node("Body") as Node3D
	body.rotation.x = -PI * 0.5
	body.position.y = 0.3
	add_to_group(&"body")


func _build_body() -> void:
	var body := Node3D.new()
	body.name = "Body"
	add_child(body)
	var robe := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.85, 0.65, 0.2)
	capsule.material = gold
	robe.mesh = capsule
	robe.position.y = 0.9
	body.add_child(robe)
	var hat := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.3
	cylinder.bottom_radius = 0.3
	cylinder.height = 0.35
	var purple := StandardMaterial3D.new()
	purple.albedo_color = Color(0.45, 0.15, 0.5)
	cylinder.material = purple
	hat.mesh = cylinder
	hat.position.y = 1.95
	body.add_child(hat)
