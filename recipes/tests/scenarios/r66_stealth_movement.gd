extends GbScenario
## R66 — stealth movement in the engine: sprint and sneak speeds; sneaking is silent, running is heard; walking into a
## roof's edge stops there; the drop intent walks off and a 5 m fall hurts; a 9 m fall into hay doesn't; a sprint leaps
## a 2.5 m gap between roofs, and a run without sprint stops at the same edge.

var _noises: Array[float] = []


func run() -> void:
	await load_scene("res://66-stealth-movement/stealth_move_demo.tscn")
	var p := node("Player") as StealthMover
	p.noise_made.connect(func(_at: Vector3, r: float) -> void: _noises.append(r))
	await wait_frames(3)

	p.teleport(Vector3(0, 0.05, 20))
	await wait(0.3)
	hold("sprint")
	hold("move_up")
	await wait(1.0)
	expect_near(_planar(p), p.profiles.speed(MoveProfiles.SPRINT), 0.2, "sprint speed")
	expect_eq(p.profile, MoveProfiles.SPRINT, "the sprint profile")
	release("sprint")
	release("move_up")
	await wait(0.6)

	p.teleport(Vector3(0, 0.05, 20))
	await wait(0.3)
	_noises.clear()
	hold("sneak")
	hold("move_up")
	await wait(1.5)
	expect_near(_planar(p), p.profiles.speed(MoveProfiles.SNEAK), 0.1, "sneak speed")
	expect(_noises.is_empty(), "sneaking makes no footstep noise (%d heard)" % _noises.size())
	release("sneak")
	await wait(1.5)
	expect(_noises.has(p.profiles.noise(MoveProfiles.RUN)), "running is heard at its radius (%s)" % [_noises])
	release("move_up")
	await wait(0.5)

	p.teleport(Vector3(20, 5.05, 3))
	await wait(0.3)
	hold("move_up")
	await wait(2.5)
	expect_gt(p.global_position.y, 4.9, "walking into the roof's edge: still on the roof")
	expect_gt(p.global_position.z, -5.0, "stopped before the edge (z %.2f)" % p.global_position.z)
	expect_eq(p.state, "edge", "the state says why")
	p.last_landing = {}
	await tap("drop")
	await wait_until(func() -> bool: return p.last_landing.has("height"), 4.0)
	release("move_up")
	expect_near(float(p.last_landing.get("height", 0.0)), 5.0, 0.2, "the drop fell 5 m")
	expect_eq(int(p.last_landing.get("kind", -1)), FallRule.Kind.HURT, "5 m is above the safe height: hurt")
	shot("r66_dropped")
	await wait(0.5)

	p.teleport(Vector3(40, 10.05, 1))
	await wait(0.3)
	hold("move_up")
	await wait(1.6)
	p.last_landing = {}
	await tap("drop")
	await wait_until(func() -> bool: return p.last_landing.has("height"), 4.0)
	release("move_up")
	expect(p.last_landing.get("soft", false) == true, "landed in the hay")
	expect_near(float(p.last_landing.get("height", 0.0)), 9.0, 0.3, "a 9 m fall")
	expect_eq(int(p.last_landing.get("kind", -1)), FallRule.Kind.NONE, "hay takes it: no damage")
	await wait(0.5)

	p.teleport(Vector3(60, 4.05, 3))
	await wait(0.3)
	hold("move_up")
	await wait(2.5)
	expect_eq(p.state, "edge", "a run without sprint stops at the gap")
	release("move_up")
	await wait(0.3)
	p.teleport(Vector3(60, 4.05, 3))
	await wait(0.3)
	var jumps := p.jumps
	p.last_landing = {}
	hold("sprint")
	hold("move_up")
	var across := await wait_until(func() -> bool: return p.is_on_floor() and p.global_position.z < -7.0, 3.0)
	release("move_up")
	release("sprint")
	expect(across, "the sprint crossed the gap")
	expect_eq(p.jumps, jumps + 1, "with one leap")
	expect_gt(p.global_position.y, 3.9, "and landed on the far roof (y %.2f)" % p.global_position.y)
	expect_near(float(p.last_landing.get("height", 0.0)), p.jump_height, 0.15, "the landing counts from the leap's peak")
	shot("r66_leap")


func _planar(p: CharacterBody3D) -> float:
	return Vector2(p.velocity.x, p.velocity.z).length()
