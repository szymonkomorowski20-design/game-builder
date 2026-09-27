extends GutTest
## R46 — MultiplayerSpawner + MultiplayerSynchronizer, a server and clients in ONE process (as in R39): every peer
## gets an avatar on every peer (late joiners too), movement is decided by the server from clamped input and
## replicated to clients, a client can't move itself or anyone else by editing its copy, leaving despawns everywhere.

var server: NetWorld
var port := 0
var _roots: Array[Node] = []


## Same relative node path ("World") under separate multiplayer roots, as spawners and synchronizers require.
func _branch(root_name: String) -> NetWorld:
	var root := Node.new()
	root.name = root_name
	add_child_autofree(root)
	_roots.append(root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), root.get_path())
	var w := NetWorld.new()
	w.name = "World"
	root.add_child(w)
	return w


func before_each() -> void:
	port = 28000 + randi() % 4000
	_roots.clear()
	server = _branch("Server")


func after_each() -> void:
	for r in _roots:
		if is_instance_valid(r):
			(r.get_node("World") as NetWorld).leave()
			get_tree().set_multiplayer(null, r.get_path())


func _until(cond: Callable, seconds: float = 3.0) -> bool:
	var t := 0.0
	while t < seconds:
		if cond.call():
			return true
		await wait_frames(1)
		t += 1.0 / 60.0
	return cond.call()


func _ids(w: NetWorld) -> Array:
	var ids := w.avatar_ids()
	ids.sort()
	return ids


## Host + one client; returns the client once both sides show both avatars.
func _join(root_name: String = "Client") -> NetWorld:
	var client := _branch(root_name)
	assert_eq(client.join("127.0.0.1", port), OK)
	var ok: bool = await _until(func():
		var id := client.multiplayer.get_unique_id()
		return client.avatar(id) != null and server.avatar(id) != null and client.avatar(1) != null)
	assert_true(ok, "%s joined and its avatar spawned on both sides" % root_name)
	return client


func _host() -> void:
	assert_eq(server.host(port), OK)
	assert_eq(_ids(server), [1], "the host has its own avatar")


func test_r46_join_spawns_avatars_everywhere() -> void:
	_host()
	var client: NetWorld = await _join()
	var id := client.multiplayer.get_unique_id()
	var expected := [1, id]
	expected.sort()
	assert_eq(_ids(server), expected, "server: host + client")
	assert_eq(_ids(client), expected, "client: host + itself")
	assert_eq(client.avatar(id).position, server.avatar(id).position, "spawned where the server put it")


func test_r46_late_joiner_sees_everyone() -> void:
	_host()
	var a: NetWorld = await _join("ClientA")
	var b: NetWorld = await _join("ClientB")
	var id_a := a.multiplayer.get_unique_id()
	var id_b := b.multiplayer.get_unique_id()
	assert_true(await _until(func(): return _ids(a).size() == 3 and _ids(b).size() == 3), "3 avatars on every peer")
	assert_eq(_ids(a), _ids(server))
	assert_eq(_ids(b), _ids(server))
	assert_not_null(b.avatar(id_a), "B (joined later) sees A, who was already there")
	assert_not_null(a.avatar(id_b), "A sees B arrive")


func test_r46_movement_is_decided_by_server_and_replicated() -> void:
	_host()
	var client: NetWorld = await _join()
	var id := client.multiplayer.get_unique_id()
	var start := server.avatar(id).position
	var host_start := server.avatar(1).position
	client.local_input(Vector2.RIGHT)
	assert_true(await _until(func(): return server.avatar(id).position.x > start.x + 10.0), "server moved the avatar")
	assert_true(await _until(func(): return client.avatar(id).position.x > start.x + 10.0), "client sees it move")
	client.local_input(Vector2.ZERO)
	assert_true(await _until_still(server.avatar(id)), "the server stopped it")
	assert_true(await _until(func(): return client.avatar(id).position == server.avatar(id).position), "client copy == server")
	assert_eq(server.avatar(id).position.y, start.y, "only horizontal movement")
	assert_eq(server.avatar(1).position, host_start, "the client's input moved only its own avatar")
	assert_eq(client.avatar(1).position, host_start)


## Waits until the node's position hasn't changed for 3 physics frames.
func _until_still(n: Node2D, seconds: float = 3.0) -> bool:
	var still := 0
	var last := n.position
	for i in int(seconds * 60.0):
		await wait_physics_frames(1)
		still = still + 1 if n.position == last else 0
		last = n.position
		if still >= 3:
			return true
	return false


func test_r46_cheating_input_is_clamped() -> void:
	_host()
	var client: NetWorld = await _join()
	var id := client.multiplayer.get_unique_id()
	client.send_input.rpc_id(1, Vector2(50, 0))   # a cheating client: 50× the speed
	var a := server.avatar(id)
	var start := a.position.x
	assert_true(await _until(func(): return a.position.x > start), "input arrived")
	var x0 := a.position.x
	var f0 := Engine.get_physics_frames()
	await wait_physics_frames(10)
	var dx := a.position.x - x0
	var steps := Engine.get_physics_frames() - f0   # count the real physics steps, not the requested ones
	var limit := NetWorld.SPEED * steps / float(Engine.physics_ticks_per_second)
	assert_gt(dx, 0.0, "still moving right")
	assert_true(dx <= limit + 0.01, "at most SPEED (%.2f px in %d steps, got %.2f)" % [limit, steps, dx])


func test_r46_nan_input_is_ignored() -> void:
	_host()
	var client: NetWorld = await _join()
	var id := client.multiplayer.get_unique_id()
	client.send_input.rpc_id(1, Vector2(NAN, 0))
	client.send_input.rpc_id(1, Vector2(INF, 0))
	await wait_physics_frames(20)
	assert_true(server.avatar(id).position.is_finite(), "server position not poisoned")
	assert_true(client.avatar(id).position.is_finite(), "nor the replicated copy")


func test_r46_client_edits_to_its_copy_are_overwritten() -> void:
	_host()
	var client: NetWorld = await _join()
	var id := client.multiplayer.get_unique_id()
	var truth := server.avatar(id).position
	client.avatar(id).position = Vector2(300, 10)   # a hacked client teleports itself locally
	await wait_frames(5)
	assert_eq(server.avatar(id).position, truth, "the server's avatar did not move")
	assert_true(await _until(func(): return client.avatar(id).position == truth), "the client's copy snapped back to the server's")


func test_r46_avatars_stay_in_bounds() -> void:
	_host()
	var client: NetWorld = await _join()
	var id := client.multiplayer.get_unique_id()
	client.local_input(Vector2.LEFT)
	var a := server.avatar(id)
	assert_true(await _until(func(): return a.position.x == server.bounds.position.x, 5.0), "stopped at the left edge")
	await wait_physics_frames(5)
	assert_eq(a.position.x, server.bounds.position.x, "never beyond it")


func test_r46_leaving_despawns_everywhere() -> void:
	_host()
	var a: NetWorld = await _join("ClientA")
	var b: NetWorld = await _join("ClientB")
	var id_a := a.multiplayer.get_unique_id()
	assert_true(await _until(func(): return b.avatar(id_a) != null), "B sees A")
	a.leave()
	assert_true(await _until(func(): return server.avatar(id_a) == null), "server despawned A")
	assert_true(await _until(func(): return b.avatar(id_a) == null), "the despawn replicated to B")
	assert_eq(a.avatar_ids(), [], "A cleared its own copies when it left")
