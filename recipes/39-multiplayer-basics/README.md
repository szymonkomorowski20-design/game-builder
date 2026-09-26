# 39 — Multiplayer basics (server-authoritative, tested in one process)

**Problem:** networked games trust clients ("I have 1000 points"), and multiplayer code is hard to test — two
game instances, ports, timing.

**Solution:** Godot's high-level multiplayer with a **server-authoritative** rule: clients call
`request_score.rpc_id(1, amount)` (`@rpc("any_peer")`), the server takes the sender id from the network layer
(`get_remote_sender_id()` — a client can't act for someone else), **validates** (clamps to
`MAX_SCORE_PER_REQUEST`) and broadcasts the state with an `@rpc("authority", "call_local")` sync. Joining/leaving
updates the state on the server only.

**Testing in one process:** give each side its own `SceneMultiplayer` with
`get_tree().set_multiplayer(api, branch_path)` — `/root/…/Server/Game` and `/root/…/Client/Game` have the same
relative path (`Game`), which RPCs require. ENet over `127.0.0.1` on a random high port; wait with a timeout
(`_until`) instead of fixed frames. The same pattern scales to 2–4 clients.

**Next steps for a real game:** `MultiplayerSpawner` (players/bullets appear on every peer) and
`MultiplayerSynchronizer` (position/animation replication with interpolation), a lobby, reconnect, and a
latency test (artificial delay) — each with its own test in this style.

**Web:** browsers have no low-level networking — only HTTP, WebSocket (client) and WebRTC (4.7 docs). Use
`WebSocketMultiplayerPeer` (a dedicated server) or `WebRTCMultiplayerPeer` with the same RPC code.

**Pitfalls:** RPC method names/paths must match on both sides; `call_local` needed when the server also plays;
`multiplayer.is_server()` checks inside every authority action; ports in use (random high port in tests);
determinism tools (replays) are single-player — multiplayer regressions need tests like these; firewalls on real
networks (a human test).

**Test:** `tests/unit/test_r39_multiplayer.gd` — join + initial state, a cheating request clamped, disconnect.
