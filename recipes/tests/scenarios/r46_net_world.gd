extends GbScenario
## R46 — a server and a client in one process, drawn side by side (left: the server's view, right: the client's).
## The player presses right on the CLIENT: the input travels to the server, the server moves the avatar, the
## synchronizer brings the new position back to the client's view. The host's avatar doesn't move.


func run() -> void:
	await load_scene("res://46-multiplayer-spawn-sync/net_world_demo.tscn")
	var demo := node(".") as NetWorldDemo
	var connected := await wait_until(func() -> bool: return demo.client_world.avatar_ids().size() == 2, 3.0)
	expect(connected, "R46 the client joined and sees 2 avatars (host + itself)")
	if not connected:
		return
	var id := demo.client_world.multiplayer.get_unique_id()
	expect_eq(demo.server_world.avatar_ids().size(), 2, "R46 the server has the same 2 avatars")
	var start := demo.server_world.avatar(id).position
	var host_start := demo.server_world.avatar(1).position
	await press("move_right", 0.5)
	var synced := await wait_until(func() -> bool:
		return demo.client_world.avatar(id).position == demo.server_world.avatar(id).position \
			and demo.server_world.avatar(id).position.x > start.x, 2.0)
	expect(synced, "R46 the client's view caught up with the server's")
	var moved := demo.server_world.avatar(id).position.x - start.x
	expect_gt(moved, 30.0, "R46 the avatar moved right on the server")
	expect_lt(moved, NetWorld.SPEED * 0.5 + 10.0, "R46 no faster than SPEED")
	expect_eq(demo.server_world.avatar(1).position, host_start, "R46 the host's avatar stayed put")
	await wait(0.2)
	await shot("net_world")
