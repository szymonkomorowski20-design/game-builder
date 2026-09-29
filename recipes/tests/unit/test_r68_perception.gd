extends GutTest
## Recipe 68 — perception rules: the vision zones and the main zone's shrinking angle, the time to notice (linear with
## distance in the main zone), each multiplier on the rate, the awareness meter (rise, thresholds, slow fall, latched
## detection, reset, honest last-seen), and when a noise is heard.

const EYE := Vector3(0, 1.6, 0)
const FWD := Vector3(0, 0, -1)


func test_r68_zones() -> void:
	var c := VisionCone.new()
	assert_eq(c.zone(EYE, FWD, Vector3(0, 1.5, -10)), VisionCone.MAIN, "10 m ahead: main")
	assert_eq(c.zone(EYE, FWD, Vector3(0, 1.5, 10)), &"", "10 m behind: nothing")
	assert_eq(c.zone(EYE, FWD, Vector3(2, 1.5, 0)), VisionCone.NEAR, "2 m beside: near")
	assert_eq(c.zone(EYE, FWD, Vector3(0, 1.5, 2)), &"", "2 m straight behind: outside even the near zone")
	assert_eq(c.zone(EYE, FWD, Vector3(5, 1.5, -0.4)), VisionCone.PERIPHERAL, "5 m to the side: peripheral")
	assert_eq(c.zone(EYE, FWD, Vector3(10, 1.5, -10)), &"", "45° at 14 m: outside the narrowed main zone")
	assert_eq(c.zone(EYE, FWD, Vector3(0, 1.5, -25)), &"", "25 m ahead: beyond range")
	assert_eq(c.zone(EYE, FWD, Vector3(0, 6.0, -10)), VisionCone.MAIN, "on a roof 10 m ahead: main (24° up)")
	assert_almost_eq(c.main_half_angle(c.near_range), c.main_angle_near, 1e-5, "wide up close")
	assert_almost_eq(c.main_half_angle(c.range), c.main_angle_far, 1e-5, "narrow far away")


func test_r68_time_and_rate() -> void:
	var c := VisionCone.new()
	var mid := (c.near_range + c.range) * 0.5
	assert_almost_eq(c.time_to_notice(VisionCone.MAIN, c.near_range), c.time_main_near, 1e-5, "main, near its start")
	assert_almost_eq(c.time_to_notice(VisionCone.MAIN, c.range), c.time_main_far, 1e-5, "main, at range")
	assert_almost_eq(c.time_to_notice(VisionCone.MAIN, mid), (c.time_main_near + c.time_main_far) * 0.5, 1e-5, "linear between")
	assert_almost_eq(c.time_to_notice(VisionCone.NEAR, 1.0), c.time_near, 1e-5, "near")
	assert_eq(c.time_to_notice(&"", 1.0), INF, "outside: never")
	var base := c.rate(VisionCone.MAIN, mid)
	assert_almost_eq(base, 1.0 / c.time_to_notice(VisionCone.MAIN, mid), 1e-5, "the rate is 1 / time")
	assert_almost_eq(c.rate(VisionCone.MAIN, mid, {shadow = true}), base * c.in_shadow, 1e-5, "shadow")
	assert_almost_eq(c.rate(VisionCone.MAIN, mid, {sneaking = true}), base * c.sneaking, 1e-5, "sneaking")
	assert_almost_eq(c.rate(VisionCone.MAIN, mid, {high_profile = true}), base * c.high_profile, 1e-5, "high profile")
	assert_almost_eq(c.rate(VisionCone.MAIN, mid, {still = true}), base * c.still, 1e-5, "standing still")
	assert_eq(c.rate(VisionCone.MAIN, mid, {blended = true}), 0.0, "blended: unseen in the main zone")
	assert_eq(c.rate(VisionCone.PERIPHERAL, 5.0, {blended = true}), 0.0, "…and the peripheral one")
	assert_almost_eq(c.rate(VisionCone.NEAR, 1.0, {blended = true}), c.blended_near / c.time_near, 1e-5, "but not right beside a guard")
	assert_almost_eq(c.rate(VisionCone.MAIN, mid, {}, &"alert"), base * c.alerted, 1e-5, "a hunting guard is faster")
	assert_almost_eq(c.rate(VisionCone.MAIN, mid, {}, &"caution"), base * c.cautious, 1e-5, "a cautious one a little")
	assert_eq(c.rate(&"", 1.0), 0.0, "outside every zone: 0")


func test_r68_meter() -> void:
	var m := AwarenessMeter.new()
	for i in 10:
		m.update(0.5, 0.1, Vector3(1, 0, 2), i * 0.1)
	assert_almost_eq(m.value, 0.5, 1e-5, "0.5 per second for a second")
	assert_eq(m.level(), AwarenessMeter.SUSPICIOUS, "above suspicious_at")
	assert_eq(m.last_seen, Vector3(1, 0, 2), "where the player was seen")
	for i in 10:
		m.update(0.5, 0.1, Vector3(3, 0, 4), 1.0 + i * 0.1)
	assert_eq(m.level(), AwarenessMeter.DETECTED, "full: detected")
	for i in 100:
		m.update(0.0, 0.1)
	assert_eq(m.value, 0.0, "falls to empty while unseen")
	assert_eq(m.level(), AwarenessMeter.DETECTED, "but detection stays latched until the brain resets it")
	assert_eq(m.last_seen, Vector3(3, 0, 4), "nothing updates the last-seen place while nobody sees the player")
	m.reset()
	assert_eq(m.level(), AwarenessMeter.UNAWARE, "reset")
	m.update(1.0, 0.3)
	for i in 5:
		m.update(0.0, 0.1)
	assert_almost_eq(m.value, 0.3 - 0.5 * m.fall_per_s, 1e-5, "the fall is slow: fall_per_s")


func test_r68_hears() -> void:
	assert_true(Hearing.hears(9.0, 8.0), "inside the radius along the path")
	assert_false(Hearing.hears(9.0, 10.0), "a longer path: silence")
	assert_false(Hearing.hears(0.0, 0.0), "a silent step is never heard")
	assert_false(Hearing.hears(9.0, INF), "no path: silence")
