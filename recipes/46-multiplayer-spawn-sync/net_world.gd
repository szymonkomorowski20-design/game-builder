class_name NetWorld
extends Node2D
## Spawning + state replication for a networked game (builds on recipe 39). The server spawns an avatar per peer
## through a MultiplayerSpawner — it appears on every peer, including peers that join later, and disappears
## everywhere when its peer leaves. Clients only SEND INPUT; the server clamps it, moves the avatars and a
## MultiplayerSynchronizer on each avatar replicates the position back to everyone. A client never sets positions.
## Desktop: ENetMultiplayerPeer. Web: ENet is unavailable — WebSocketMultiplayerPeer/WebRTC with the same nodes.

signal avatar_added(id: int)
signal avatar_removed(id: int)

const SPEED := 120.0   ## px/s — the server's limit, whatever a client sends

@export var bounds := Rect2(12, 12, 296, 336)   ## the server keeps avatars inside

var players: Node2D                 ## spawn root; avatars are named by peer id
var spawner: MultiplayerSpawner
var _inputs := {}                   ## peer id -> Vector2 (server only)
var _hosting := false
var _peer: MultiplayerPeer          ## ours, so it can be closed even after we left the tree


func _init() -> void:
	players = Node2D.new()
	players.name = "Players"
	add_child(players)
	spawner = MultiplayerSpawner.new()
	spawner.name = "Spawner"
	spawner.spawn_path = NodePath("../Players")
	spawner.spawn_function = _spawn_avatar   # runs on EVERY peer, with the data the server passed to spawn()
	add_child(spawner)
	players.child_entered_tree.connect(func(n: Node) -> void: avatar_added.emit(int(str(n.name))))
	players.child_exiting_tree.connect(func(n: Node) -> void: avatar_removed.emit(int(str(n.name))))


func host(port: int, with_avatar: bool = true, max_clients: int = 8) -> Error:
	var peer := ENetMultiplayerPeer.new()
	peer.set_bind_ip("127.0.0.1" if port >= 20000 else "*")
	var err := peer.create_server(port, max_clients)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_peer = peer
	_hosting = true
	_connect_signals()
	if with_avatar:
		_spawn_for(1)
	return OK


func join(address: String, port: int) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_peer = peer
	_connect_signals()
	return OK


func leave() -> void:
	if _peer != null:
		_peer.close()
		if multiplayer.multiplayer_peer == _peer:
			multiplayer.multiplayer_peer = null
	_peer = null
	_hosting = false
	_inputs.clear()
	_clear_avatars()


func avatar(id: int) -> NetAvatar:
	return players.get_node_or_null(str(id)) as NetAvatar


func avatar_ids() -> Array:
	var ids := []
	for a in players.get_children():
		if not a.is_queued_for_deletion():
			ids.append(int(str(a.name)))
	return ids


## Call every physics frame with the local player's direction (host: applied directly; client: sent to the server).
func local_input(dir: Vector2) -> void:
	if _hosting:
		_set_input(1, dir)
	elif _peer != null and _peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		send_input.rpc_id(1, dir)


## Client → server. Unreliable-ordered because it is resent every frame; the sender id comes from the network
## layer, so a client can only steer its own avatar.
@rpc("any_peer", "call_remote", "unreliable_ordered")
func send_input(dir: Vector2) -> void:
	if not _hosting:
		return
	_set_input(multiplayer.get_remote_sender_id(), dir)


func _set_input(id: int, dir: Vector2) -> void:
	if avatar(id) == null or not dir.is_finite():   # NaN/INF from a hostile client would poison the position
		return
	_inputs[id] = dir.limit_length(1.0)              # a client asking for 50× speed gets 1×


func _physics_process(delta: float) -> void:
	if not _hosting:
		return
	for id: int in _inputs:
		var a := avatar(id)
		if a != null:
			a.position = (a.position + _inputs[id] * SPEED * delta).clamp(bounds.position, bounds.end)


func _exit_tree() -> void:
	if _peer != null:   # freed with the scene: don't leave a socket open (children leave the tree before parents)
		_peer.close()


func _connect_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		multiplayer.server_disconnected.connect(_clear_avatars)


func _on_peer_connected(id: int) -> void:
	if _hosting:
		_spawn_for(id)


func _on_peer_disconnected(id: int) -> void:
	if not _hosting:
		return
	_inputs.erase(id)
	var a := avatar(id)
	if a != null:
		a.queue_free()   # the spawner sees it leave the spawn root and despawns it on every peer


func _spawn_for(id: int) -> void:
	var slot := players.get_child_count()
	var at := Vector2(bounds.position.x + 40.0 + 60.0 * (slot % 4), bounds.position.y + 60.0 + 80.0 * floorf(slot / 4.0))
	spawner.spawn([id, at])


func _spawn_avatar(data: Array) -> Node:
	var a := NetAvatar.new()
	a.name = str(data[0])
	a.peer_id = data[0]
	a.position = data[1]
	return a   # not added here — the spawner adds it under spawn_path


func _clear_avatars() -> void:
	for a in players.get_children():
		players.remove_child(a)
		a.queue_free()
