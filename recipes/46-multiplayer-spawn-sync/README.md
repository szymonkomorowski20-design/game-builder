# 46 — Multiplayer spawning + sync (MultiplayerSpawner, MultiplayerSynchronizer, tested in one process)

**Problem:** recipe 39 syncs a dictionary by hand. Real games need *things* on every peer — avatars, bullets,
pickups — that appear for players who join later, vanish everywhere when their owner leaves, and move smoothly
without every client being able to teleport itself.

**Solution (server-authoritative, extends recipe 39):** `NetWorld` has a `Players` spawn root and a
`MultiplayerSpawner` with a `spawn_function`. The server calls `spawner.spawn([peer_id, position])` when a peer
connects; the spawner runs the same function on every peer (late joiners get all existing avatars on connect) and
despawns everywhere when the server frees the node. Each `NetAvatar` carries a `MultiplayerSynchronizer`
(authority = server, peer 1 — the default) replicating `position` in **ALWAYS** mode and in the spawn packet.
Clients only send input: `send_input.rpc_id(1, dir)` every physics frame (`unreliable_ordered`); the server takes the
sender from the network layer, rejects NaN/INF, clamps the length to 1, moves at `SPEED` and keeps avatars in
`bounds`. A client editing its own copy is overwritten by the next sync packet.

**Tuning:** `SPEED`, `bounds`, spawn slots (`_spawn_for`), which properties the synchronizer replicates (add
`rotation`, an animation state, HP…), `replication_interval` (0 = every frame) for bandwidth.

**Testing in one process:** as in recipe 39 — each side is its own `SceneMultiplayer` root
(`get_tree().set_multiplayer(api, branch_path)`), the same relative path `World/...` on all peers, ENet over
`127.0.0.1` on a random high port, waits with a timeout. Three roots (server + 2 clients) test late joiners and
despawn replication. Demo: `net_world_demo.tscn` shows the server's and the client's world side by side; the
keyboard steers the client's avatar.

**Pitfalls (each one measured here):**
- **ON_CHANGE for moving state:** only changes are sent, so a tampered or stale client copy stays wrong. With ALWAYS
  the next packet corrects it (switching the mode turns `test_r46_client_edits_to_its_copy_are_overwritten` red).
- **NaN/INF input:** `limit_length` of a NaN vector is NaN and poisons the position for everyone — check
  `is_finite()` first.
- **Input only "on change" over an unreliable channel:** a lost "stop" packet keeps the avatar walking forever.
  Resend every frame (unreliable) or send changes reliably.
- **The spawn function must return a node NOT in the tree, with its name already set** — the spawner adds it, and
  paths (`Players/<id>/Sync`) must match on every peer.
- **Cleanup order:** children leave the tree before their parent, so a parent's `_exit_tree` can't reach its
  children's `multiplayer`. `NetWorld` keeps its own peer and closes it in its own `_exit_tree`.
- **Node2D under a plain Node** loses the parent's transform (the demo's halves are Node2D all the way down).
- **Test timing:** GUT's `wait_physics_frames(10)` can take 11 steps — count `Engine.get_physics_frames()`.

**Next steps for a real game:** client-side interpolation between sync packets (smooth at 20–30 Hz), prediction
of the local player with server reconciliation, `set_visibility_for` for interest management (don't send far
things), `MultiplayerSpawner.spawn_limit`, a latency/packet-loss test (artificial delay).

**Web:** the same nodes over `WebSocketMultiplayerPeer` (dedicated server) or `WebRTCMultiplayerPeer`.

**Test:** `tests/unit/test_r46_net_world.gd` (join, late joiner, movement, clamped and NaN input, tampered copy,
bounds, despawn), `tests/scenarios/r46_net_world.gd` (+ screenshot `net_world`).
