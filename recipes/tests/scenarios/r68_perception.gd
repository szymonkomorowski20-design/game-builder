extends GbScenario
## R68 — perception in the engine: in the main zone, standing and lit, the guard notices after 1 / rate seconds;
## shadow slows it to its multiplier; blended into a crowd, not at all; a wall blocks sight; behind the guard nothing,
## beside him (near) fast, to the side (peripheral) slowly. Hearing: a sprint behind the guard is heard, sneaking isn't;
## a noise 5 m away behind a 20 m wall is not heard, the same noise in front is, a loud one goes around the wall, and a
## noise on a roof (off the navigation mesh) travels straight.

var _heard_a: Array[float] = []
var _heard_b: Array[float] = []


func run() -> void:
	await load_scene("res://68-stealth-perception/perception_demo.tscn")
	var p := node("Player") as StealthMover
	var a := node("GuardA/Senses") as GuardSenses
	var b := node("GuardB/Senses") as GuardSenses
	var baked := await wait_until(func() -> bool:
		return NavigationServer3D.map_get_iteration_id(p.get_world_3d().navigation_map) > 0, 3.0)
	expect(baked, "the navigation mesh is ready")

	p.teleport(Vector3(3, 0.05, -10))
	await wait_frames(2)
	expect(p.stealth_cues().get("still", false) == true, "a player standing still reads as still")
	var head := p.global_position + Vector3.UP * 1.7
	var expected := 1.0 / a.cone.rate(VisionCone.MAIN, a.global_position.distance_to(head), p.stealth_cues())
	a.meter.reset()
	var t0 := a.clock
	var detected := await wait_until(func() -> bool: return a.meter.detected, expected + 2.0)
	expect(detected, "seen in the main zone")
	expect_near(a.clock - t0, expected, 0.25, "after 1 / rate seconds (%.2f s expected)" % expected)
	expect_eq(a.zone_seen, VisionCone.MAIN, "in the main zone")
	shot("r68_seen")

	a.meter.reset()
	p.in_shadow = true
	await wait(1.0)
	var in_shadow := a.meter.value
	p.in_shadow = false
	a.meter.reset()
	await wait(1.0)
	var lit := a.meter.value
	expect_near(in_shadow / lit, a.cone.in_shadow, 0.1, "shadow slows noticing to its multiplier")
	p.blended = true
	a.meter.reset()
	await wait(2.0)
	p.blended = false
	expect_eq(a.meter.value, 0.0, "blended into a crowd: unseen at 10 m")

	p.teleport(Vector3(-5, 0.05, -12))
	await wait_frames(2)
	a.meter.reset()
	await wait(3.0)
	expect_eq(a.meter.value, 0.0, "behind the wall: nothing (line of sight)")

	p.teleport(Vector3(0, 0.05, 5))
	await wait_frames(2)
	a.meter.reset()
	await wait(3.0)
	expect_eq(a.meter.value, 0.0, "5 m behind the guard: nothing")

	p.teleport(Vector3(2.0, 0.05, 0.0))
	await wait_frames(2)
	a.meter.reset()
	t0 = a.clock
	await wait_until(func() -> bool: return a.meter.detected, 2.0)
	expect_eq(a.zone_seen, VisionCone.NEAR, "2 m beside the guard: the near zone")
	expect_lt(a.clock - t0, 1.0, "noticed within a second")

	p.teleport(Vector3(5, 0.05, -0.4))
	await wait_frames(2)
	a.meter.reset()
	await wait(1.0)
	expect_eq(a.zone_seen, VisionCone.PERIPHERAL, "5 m to the side: peripheral")
	expect(a.meter.value > 0.0 and a.meter.value < a.meter.suspicious_at,
			"slowly: still below suspicious after 1 s (%.2f)" % a.meter.value)

	a.heard.connect(func(_at: Vector3, r: float) -> void: _heard_a.append(r))
	b.heard.connect(func(_at: Vector3, r: float) -> void: _heard_b.append(r))
	p.noise_made.connect(a.hear)
	p.teleport(Vector3(0, 0.05, 4))
	await wait(0.3)
	_heard_a.clear()
	hold("sprint")
	hold("move_down")
	await wait(0.8)
	expect(p.stealth_cues().get("high_profile", false) == true, "a sprinting player reads as high profile")
	release("move_down")
	release("sprint")
	expect_gt(_heard_a.size(), 0, "sprinting behind the guard is heard")
	p.teleport(Vector3(0, 0.05, 4))
	await wait(0.3)
	_heard_a.clear()
	hold("sneak")
	hold("move_down")
	await wait(1.5)
	var cues := p.stealth_cues()
	expect(cues.get("sneaking", false) == true and cues.get("still", true) == false, "a sneaking player reads as sneaking and moving")
	release("move_down")
	release("sneak")
	expect_eq(_heard_a.size(), 0, "sneaking is not")

	b.hear(Vector3(30, 0, 5), 9.0)
	expect_eq(_heard_b.size(), 0, "5 m away behind a 20 m wall: the way round is too long")
	b.hear(Vector3(30, 0, -5), 9.0)
	expect_eq(_heard_b.size(), 1, "the same noise in front: heard")
	b.hear(Vector3(30, 0, 5), 25.0)
	expect_eq(_heard_b.size(), 2, "a loud noise goes round the wall")
	b.hear(Vector3(30, 8, 5), 9.0)
	expect_eq(_heard_b.size(), 2, "on a roof, off the mesh: straight distance 9.4 m > 9")
	b.hear(Vector3(30, 8, 5), 10.0)
	expect_eq(_heard_b.size(), 3, "and heard at 10 m")
