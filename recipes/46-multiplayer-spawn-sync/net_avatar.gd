class_name NetAvatar
extends Node2D
## One player's avatar, created by NetWorld's spawner on every peer. Its MultiplayerSynchronizer (authority: the
## server, peer 1 — the default) sends `position` to every client each frame (ALWAYS mode) and includes it in the
## spawn packet, so a late joiner sees it in the right place at once.

var peer_id := 0


func _init() -> void:
	var cfg := SceneReplicationConfig.new()
	var prop := NodePath(".:position")
	cfg.add_property(prop)
	cfg.property_set_spawn(prop, true)
	# ALWAYS: sent unreliably every frame, so a local edit on a client is overwritten by the next packet.
	# ON_CHANGE only sends when the server's value changes — a tampered/stale client copy would stay wrong.
	cfg.property_set_replication_mode(prop, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	sync.replication_config = cfg   # root_path defaults to ".." = this avatar
	add_child(sync)


func _draw() -> void:
	var mine := is_inside_tree() and multiplayer.get_unique_id() == peer_id
	draw_rect(Rect2(-8, -8, 16, 16), Color(0.45, 0.8, 1.0) if mine else Color(1.0, 0.6, 0.3))
