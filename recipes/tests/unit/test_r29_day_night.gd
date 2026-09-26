extends GutTest
## R29 — phases in order, each emitted once, day counter wraps, clock text, noon brighter than midnight, tint applied.


func _cycle() -> DayCycle:
	var c := DayCycle.new()
	c.day_length = 100.0
	c.time = 0.0
	c.set_process(false)
	add_child_autofree(c)
	return c


func test_r29_phases_in_order_once_per_day() -> void:
	var c := _cycle()
	var seen: Array = []
	c.phase_changed.connect(func(p): seen.append(p))
	for i in 1000:
		c.advance(0.1)   # exactly one day in small steps
	assert_eq(seen, [&"dawn", &"day", &"dusk", &"night"])
	assert_eq(c.day, 2)


func test_r29_clock() -> void:
	var c := _cycle()
	c.time = 0.5
	assert_eq(c.clock(), "12:00")
	c.time = 0.25
	assert_eq(c.clock(), "06:00")


func test_r29_noon_brighter_and_tint_applied() -> void:
	var c := _cycle()
	var mod := CanvasModulate.new()
	add_child_autofree(mod)
	c.tint = mod
	c.time = 0.0
	var night := c.light_color().get_luminance()
	c.advance(50.0)   # to noon
	assert_gt(c.light_color().get_luminance(), night + 0.3)
	assert_eq(mod.color, c.light_color())
