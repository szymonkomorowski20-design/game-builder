class_name RogueDoor
extends Area3D
## An exit that shows what lies behind it (room type + reward) before the player commits. Walking into it chooses it.

signal entered

const COLORS := {
	RoomDoor.Type.COMBAT: Color(0.85, 0.85, 0.9),
	RoomDoor.Type.ELITE: Color(1.0, 0.5, 0.3),
	RoomDoor.Type.SHOP: Color(1.0, 0.85, 0.3),
	RoomDoor.Type.REST: Color(0.4, 1.0, 0.6),
	RoomDoor.Type.BOSS: Color(0.8, 0.3, 1.0),
}

var door: RoomDoor
var _used := false


func setup(d: RoomDoor) -> void:
	door = d
	($Label as Label3D).text = d.label()
	($Label as Label3D).modulate = COLORS.get(d.type, Color.WHITE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLORS.get(d.type, Color.WHITE)
	mat.emission_enabled = true
	mat.emission = COLORS.get(d.type, Color.WHITE) * 0.4
	($Frame as MeshInstance3D).material_override = mat
	body_entered.connect(_on_body)


func _on_body(body: Node3D) -> void:
	if not _used and body is RoguePlayer:
		_used = true
		entered.emit()
