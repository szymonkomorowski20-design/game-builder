class_name NetGame
extends Node
## Server-authoritative basics with Godot's high-level multiplayer: clients *ask* (RPC to the server), the
## server *validates and decides*, then broadcasts the state. Never trust a client's numbers.
## Desktop: ENetMultiplayerPeer. Web: ENet is unavailable — use WebSocketMultiplayerPeer/WebRTC with the same RPCs.

signal scores_changed(scores: Dictionary)
signal peer_joined(id: int)
signal peer_left(id: int)

const MAX_SCORE_PER_REQUEST := 10

var scores: Dictionary = {}   ## peer id -> score (server is the source of truth, clients hold a copy)


func host(port: int, max_clients: int = 8) -> Error:
	var peer := ENetMultiplayerPeer.new()
	peer.set_bind_ip("127.0.0.1" if OS.has_feature("editor") or port >= 20000 else "*")
	var err := peer.create_server(port, max_clients)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_connect_signals()
	return OK


func join(address: String, port: int) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_connect_signals()
	return OK


func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null


func _connect_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		scores[id] = 0
		_sync_scores.rpc(scores)
	peer_joined.emit(id)


func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		scores.erase(id)
		_sync_scores.rpc(scores)
	peer_left.emit(id)


## Client → server: "I scored". The server clamps and applies it; the sender id comes from the network layer,
## so a client cannot add points to someone else.
@rpc("any_peer", "call_remote", "reliable")
func request_score(amount: int) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if not scores.has(id):
		return
	scores[id] += clampi(amount, 0, MAX_SCORE_PER_REQUEST)
	_sync_scores.rpc(scores)


@rpc("authority", "call_local", "reliable")
func _sync_scores(new_scores: Dictionary) -> void:
	scores = new_scores.duplicate()
	scores_changed.emit(scores)
