class_name RogueDoor
extends Area3D
## An exit that shows what lies behind it (room type + reward) before the player commits. Walking into it chooses it —
## once it is armed: for `arm_time` after it appears it ignores bodies. The hero was just teleported to the room's
## start and the physics server may still have them at the old door, which is exactly where a rest room's doors appear
## at once (found by the proof game's scenario A3: the hero went straight through the next door).

signal entered

const COLORS := {
	RoomDoor.Type.COMBAT: Color(0.85, 0.85, 0.9),
	RoomDoor.Type.ELITE: Color(1.0, 0.5, 0.3),
	RoomDoor.Type.SHOP: Color(1.0, 0.85, 0.3),
	RoomDoor.Type.REST: Color(0.4, 1.0, 0.6),
	RoomDoor.Type.BOSS: Color(0.8, 0.3, 1.0),
}

@export var arm_time := 0.3   ## s

var door: RoomDoor
var _used := false
var _armed_in := 0.0


func setup(d: RoomDoor) -> void:
	door = d
	($Label as Label3D).text = d.label()
	($Label as Label3D).modulate = COLORS.get(d.type, Color.WHITE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLORS.get(d.type, Color.WHITE)
	mat.emission_enabled = true
	mat.emission = COLORS.get(d.type, Color.WHITE) * 0.4
	($Frame as MeshInstance3D).material_override = mat
	_armed_in = arm_time
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	if _armed_in > 0.0:
		_armed_in -= delta
		if _armed_in <= 0.0:
			for b in get_overlapping_bodies():
				_on_body(b)   # standing in it when it arms counts as walking in


func _on_body(body: Node3D) -> void:
	if not _used and _armed_in <= 0.0 and body is RoguePlayer:
		_used = true
		entered.emit()
