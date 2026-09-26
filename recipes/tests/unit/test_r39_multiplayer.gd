extends GutTest
## R39 — a server and a client in ONE process (two SceneMultiplayer instances on separate branches, ENet over
## localhost): the client joins, asks for points, the server clamps them (no cheating), both sides see the same
## state; disconnect removes the player.

var server: NetGame
var client: NetGame
var port := 0


## Same relative node path ("Game") under two multiplayer roots, as RPCs require.
func _branch(root_name: String) -> NetGame:
	var root := Node.new()
	root.name = root_name
	add_child_autofree(root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), root.get_path())
	var g := NetGame.new()
	g.name = "Game"
	root.add_child(g)
	return g


func before_each() -> void:
	port = 24000 + randi() % 4000
	server = _branch("Server")
	client = _branch("Client")


func after_each() -> void:
	client.leave()
	server.leave()
	for n in ["Server", "Client"]:
		var r := get_node_or_null(n)
		if r != null:
			get_tree().set_multiplayer(null, r.get_path())


func _until(cond: Callable, seconds: float = 3.0) -> bool:
	var t := 0.0
	while t < seconds:
		if cond.call():
			return true
		await wait_frames(1)
		t += 1.0 / 60.0
	return cond.call()


func _connect() -> int:
	assert_eq(server.host(port), OK)
	assert_eq(client.join("127.0.0.1", port), OK)
	var ok: bool = await _until(func(): return server.scores.size() == 1 and client.scores.size() == 1)
	assert_true(ok, "client connected and received the initial state")
	return client.multiplayer.get_unique_id()


func test_r39_join_and_initial_state() -> void:
	var id: int = await _connect()
	assert_eq(server.scores, {id: 0})
	assert_eq(client.scores, {id: 0})


func test_r39_request_is_validated_by_the_server() -> void:
	var id: int = await _connect()
	client.request_score.rpc_id(1, 5)
	assert_true(await _until(func(): return client.scores.get(id, 0) == 5), "5 points applied and synced")
	client.request_score.rpc_id(1, 1000)   # a cheating client
	assert_true(await _until(func(): return client.scores.get(id, 0) == 15), "clamped to MAX_SCORE_PER_REQUEST (10)")
	assert_eq(server.scores[id], 15, "server is the source of truth")


func test_r39_disconnect_removes_player() -> void:
	var id: int = await _connect()
	client.leave()
	assert_true(await _until(func(): return not server.scores.has(id)), "server dropped the player")
