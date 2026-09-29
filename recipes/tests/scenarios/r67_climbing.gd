extends GbScenario
## R67 — climbing in the engine: running into a wall doesn't climb; a jump at the wall grabs the first hold and holding
## up climbs hold by hold onto the roof; at the roof's edge the drop intent hangs from it and holding down climbs down
## to the lowest hold; drop lets go; a shimmy stops before a hold's end and a side jump crosses the gap; a sprint
## steps onto a crate and vaults a fence.

var _tops: Array[float] = []


func run() -> void:
	await load_scene("res://67-climb-ledges/climb_demo.tscn")
	var p := node("Player") as StealthMover
	var c := node("Climber") as Climber
	c.grabbed.connect(func(l: Dictionary) -> void: _tops.append(float(l.top_y)))
	await wait_frames(3)

	p.teleport(Vector3(2, 0.05, 2.0))
	await wait(0.3)
	await press("move_up", 1.2)
	expect_eq(c.state, &"none", "running into the wall doesn't climb")
	expect_lt(p.global_position.y, 0.2, "still on the ground")

	p.teleport(Vector3(-2, 0.05, 2.0))
	await wait(0.3)
	hold("move_up")
	await wait(0.6)
	await tap("jump")
	var grabbed := await wait_until(func() -> bool: return c.state != &"none", 2.0)
	expect(grabbed, "a jump at the wall grabs a hold")
	var on_roof := await wait_until(func() -> bool:
		return c.state == &"none" and p.is_on_floor() and p.global_position.y > 5.9, 8.0)
	release("move_up")
	expect(on_roof, "holding up climbs onto the roof (y %.2f)" % p.global_position.y)
	expect_eq(_decimetres(), [22, 34, 46, 60], "hold by hold: 2.2, 3.4, 4.6, the roof's edge")
	expect_eq(c.moves, 5, "five moves: four holds and over the edge")
	shot("r67_on_roof")

	p.teleport(Vector3(-2, 6.05, -1.5))
	await wait(0.3)
	_tops.clear()
	hold("move_down")
	await wait(1.2)
	expect_eq(p.state, "edge", "the edge holds the body on the roof")
	await tap("drop")
	var down := await wait_until(func() -> bool: return _tops.size() >= 4 and c.state == &"hang", 8.0)
	release("move_down")
	expect(down, "the drop hangs from the edge and holding down climbs down")
	expect_eq(_decimetres(), [60, 46, 34, 22], "the edge, then 4.6, 3.4, 2.2")
	await wait(0.3)
	expect_eq(c.state, &"hang", "nothing below the lowest hold: still hanging")
	await tap("drop")
	var landed := await wait_until(func() -> bool: return c.state == &"none" and p.is_on_floor(), 2.0)
	expect(landed and p.global_position.y < 0.2, "drop lets go, down to the street")

	expect(c.hang_at(Vector3(-2, 3.4, 0.0), Vector3(0, 0, -1)), "hang_at snaps onto the 3.4 hold")
	hold("move_right")
	await wait(2.0)
	expect_eq(c.state, &"hang", "the shimmy ends hanging")
	var x_end := p.global_position.x
	expect(x_end > -0.9 and x_end < -0.2, "and stops before the hold's end at x = 0 (x %.2f)" % x_end)
	await tap("jump")
	var across := await wait_until(func() -> bool: return c.state == &"hang" and p.global_position.x > 1.0, 2.0)
	release("move_right")
	expect(across, "jump + right crosses the 1.2 m gap (x %.2f)" % p.global_position.x)
	expect_near(float(c.ledge.get("top_y", 0.0)), 3.4, 0.05, "onto the same hold's other part")
	shot("r67_side_jump")
	await tap("drop")
	await wait_until(func() -> bool: return p.is_on_floor(), 2.0)

	p.teleport(Vector3(16, 0.05, 2.0))
	await wait(0.3)
	_tops.clear()
	hold("move_up")
	await wait(0.6)
	await tap("jump")
	await wait_until(func() -> bool: return c.state == &"hang", 2.0)
	release("move_up")
	expect_eq(_decimetres(), [22], "a knee-high lip is skipped: the grab takes the hold above it")
	await tap("drop")
	await wait_until(func() -> bool: return p.is_on_floor(), 2.0)

	p.teleport(Vector3(9, 0.05, 6))
	await wait(0.3)
	var m0 := c.moves
	hold("sprint")
	hold("move_up")
	var on_crate := await wait_until(func() -> bool:
		return c.moves > m0 and c.state == &"none" and p.is_on_floor(), 3.0)
	release("move_up")
	release("sprint")
	expect(on_crate, "a sprint into the crate steps onto it")
	expect_near(p.global_position.y, 1.1, 0.1, "standing on the crate's top")

	p.teleport(Vector3(-9, 0.05, 6))
	await wait(0.3)
	m0 = c.moves
	hold("sprint")
	hold("move_up")
	var vaulted := await wait_until(func() -> bool:
		return c.moves > m0 and c.state == &"none" and p.is_on_floor() and p.global_position.z < 2.9, 3.0)
	release("move_up")
	release("sprint")
	expect(vaulted, "a sprint into the fence vaults it (z %.2f)" % p.global_position.z)
	expect_lt(p.global_position.y, 0.2, "and lands on the far side")


## The grabbed holds' heights in whole decimetres (floats from ray hits never compare equal to literals).
func _decimetres() -> Array:
	return _tops.map(func(t: float) -> int: return roundi(t * 10.0))
