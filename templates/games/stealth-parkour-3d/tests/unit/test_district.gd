extends GutTest
## The district's contracts (template stealth-parkour-3d): the layout keeps the promises the scenarios rely on, so an
## edit to DistrictMap that breaks one fails here first — holds within the climber's reach, roofs that are leapable or
## clearly not, walkable points outside the buildings, a short target routine with a window to strike, a viewpoint
## that reveals the target's house, a hay pile under the tower's leap, and the hits it takes to kill.


func _boxes() -> Array:
	var out := []
	for h: Array in DistrictMap.HOUSES:
		out.append([h[0], h[1], h[2], h[3], h[4]])
	out.append(DistrictMap.PALAZZO)
	out.append(DistrictMap.TOWER)
	for p: Vector3 in DistrictMap.STALLS:
		out.append([p.x - 1.0, p.x + 1.0, p.z - 0.5, p.z + 0.5, 1.2])
	for h: Array in DistrictMap.HAYS:
		var c: Vector3 = h[0]
		var s: Vector3 = h[1]
		out.append([c.x - s.x * 0.5, c.x + s.x * 0.5, c.z - s.z * 0.5, c.z + s.z * 0.5, s.y])
	return out


func _inside(p: Vector3, margin: float) -> bool:
	for b: Array in _boxes():
		if p.x > b[0] - margin and p.x < b[1] + margin and p.z > b[2] - margin and p.z < b[3] + margin:
			return true
	return false


func test_holds_within_reach() -> void:
	var climber := Climber.new()
	for h: Array in DistrictMap.HOUSES + [DistrictMap.PALAZZO + ["s"], DistrictMap.TOWER + ["nsew"]]:
		var height: float = h[4]
		var top := 2.2
		while top + 1.2 <= height - 0.8 + 1e-4:
			top += 1.2
		assert_lte(2.2, climber.grab_max, "the first hold is a standing grab")
		assert_lte(height - top, climber.reach_up, "from the last hold the roof's edge is in reach (h %.1f)" % height)
		assert_gte(height - top, 0.45, "and not so close it is skipped")
	climber.free()


func test_roofs_leapable_or_clearly_not() -> void:
	var houses: Array = DistrictMap.HOUSES + [DistrictMap.PALAZZO]
	for i in houses.size():
		for j in range(i + 1, houses.size()):
			var a: Array = houses[i]
			var b: Array = houses[j]
			if a[4] != b[4]:
				continue
			var gap_x := maxf(b[0] - a[1], a[0] - b[1])
			var gap_z := maxf(b[2] - a[3], a[2] - b[3])
			var overlap_z := minf(a[3], b[3]) - maxf(a[2], b[2]) > 0.0
			var overlap_x := minf(a[1], b[1]) - maxf(a[0], b[0]) > 0.0
			var gap := gap_x if overlap_z else (gap_z if overlap_x else INF)
			if gap > 0.0 and gap < INF:
				assert_true(gap <= 2.5 or gap >= 6.0, "a gap of %.1f m between roofs: leapable (≤ 2.5) or not (≥ 6)" % gap)


func test_walkable_points_outside_buildings() -> void:
	for g: Array in DistrictMap.GUARDS:
		if (g[1] as Vector3).y < 1.0:
			assert_false(_inside(g[1], 0.4), "guard post %s is walkable" % g[0])
		for p: Vector3 in g[3]:
			assert_false(_inside(p, 0.4), "patrol point %s is walkable" % p)
	for p: Vector3 in DistrictMap.SEARCH_POINTS:
		assert_false(_inside(p, 0.4), "search point %s is walkable" % p)
	for s: Array in DistrictMap.TARGET_STOPS:
		assert_false(_inside(s[0], 0.4), "target stop %s is walkable" % s[0])
	assert_false(_inside(DistrictMap.PLAYER_START, 0.4), "the start is walkable")


func test_target_routine_short_with_a_window() -> void:
	var r := DistrictMap.routine()
	assert_lte(r.loop_time(), 120.0, "a short loop: nobody waits minutes for it to come round (%.0f s)" % r.loop_time())
	for w in r.waits:
		assert_gte(w, 8.0, "each stop is long enough to plan a strike")


func test_viewpoint_reveals_the_target_house() -> void:
	var d := Vector2(DistrictMap.DOOR.x - DistrictMap.VIEWPOINT.x, DistrictMap.DOOR.z - DistrictMap.VIEWPOINT.z).length()
	assert_lte(d, DistrictMap.VIEWPOINT_RADIUS, "the sync reveals the contract's lead (%.1f m)" % d)


func test_hay_under_the_leap() -> void:
	var m := StealthMover.new()
	var g := 2.0 * m.jump_height / (m.jump_time_to_apex * m.jump_time_to_apex)
	var rise := m.jump_time_to_apex
	var fall := sqrt(2.0 * (DistrictMap.TOWER[4] + m.jump_height - 1.0) / (g * m.fall_gravity_scale))
	var air_time := rise + fall
	var run := m.profiles.speed(MoveProfiles.RUN)
	# From a standstill at the edge, the stick held: air control accelerates the body up to the run speed.
	var a := m.acceleration * m.air_control
	var t_cap := minf(run / a, air_time)
	var near_d := 0.5 * a * t_cap * t_cap + run * (air_time - t_cap)
	var far_d := run * air_time
	var edge: float = DistrictMap.TOWER[1] - 0.45
	var hay: Array = DistrictMap.HAYS[0]
	var x0: float = (hay[0] as Vector3).x - (hay[1] as Vector3).x * 0.5
	var x1: float = (hay[0] as Vector3).x + (hay[1] as Vector3).x * 0.5
	assert_lte(x0 + 0.5, edge + near_d, "a jump from a standstill lands in the hay (%.1f m out)" % near_d)
	assert_gte(x1 - 0.5, edge + far_d, "a running leap lands in it too (%.1f m out; the hay ends %.1f m out)" % [far_d,
			x1 - edge])
	m.free()


func test_falls_cost_health() -> void:
	var player := Assassin.new()
	player._on_landed(3.0, {kind = FallRule.Kind.NONE, damage = 0.0})
	assert_eq(player.health, 5, "a safe fall costs nothing")
	player._on_landed(8.0, {kind = FallRule.Kind.HURT, damage = 0.37})
	assert_eq(player.health, 3, "a hurting fall costs its share of full health (0.37 × 5 → 2 hits)")
	player._on_landed(20.0, {kind = FallRule.Kind.DEAD, damage = 1.0})
	assert_eq(player.health, 0, "a deadly one kills")
	assert_false(player.alive, "dead")
	player.free()


func test_hits_to_kill() -> void:
	var guard := GuardAgent.new()
	var player := Assassin.new()
	assert_eq(guard.max_health, 3, "three hits kill a guard (a strike or a counter each; a perfect counter is two)")
	assert_eq(player.max_health, 5, "the player survives four hits")
	guard.free()
	player.free()
