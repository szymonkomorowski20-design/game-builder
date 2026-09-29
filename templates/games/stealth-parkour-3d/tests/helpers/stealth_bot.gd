class_name StealthBot
extends RefCounted
## A bot's hands for the district's scenarios (template stealth-parkour-3d). It drives the real input actions: the
## camera is turned to face north (yaw 0), so "move up" is −Z and a world direction maps straight onto the stick; the
## stick is analog (Input.action_press with a strength), like a pad.

var s: GbScenario
var game: StealthGame


func _init(scenario: GbScenario, p_game: StealthGame) -> void:
	s = scenario
	game = p_game
	face_north()


## Movement scenarios test the body, not the guards: freeze every guard where it stands (but `keep`).
func calm_guards(keep: StringName = &"") -> GuardAgent:
	var kept: GuardAgent = null
	for g in game.guards:
		if g.guard_name == keep:
			kept = g
		else:
			g.process_mode = Node.PROCESS_MODE_DISABLED
	return kept


## Stop the crowd where it stands (tests that place civilians by hand).
func freeze_crowd() -> void:
	game.crowd_frozen = true


## Press counter just before each of `guard`'s hits for `seconds`: a counter every strike (recipe 71's window).
func counter_strikes(guard: GuardAgent, seconds: float, lead: float = 0.2) -> void:
	var answered := {}
	await s.wait_until(func() -> bool:
		if not guard.alive:
			return true
		if guard.strike != null:
			var hit: float = guard.strike.hit_times(guard.strike_start)[0]
			var key := "%.3f" % hit
			if not answered.has(key) and game.clock >= hit - lead:
				answered[key] = true
				Input.action_press(&"counter")
		elif Input.is_action_pressed(&"counter"):
			Input.action_release(&"counter")
		return false, seconds)
	Input.action_release(&"counter")


func face_north() -> void:
	game.camera_rig.yaw = 0.0
	game.camera_rig.orbit(0.0, 0.0)


## Push the stick toward world direction `dir` (flat); a zero vector lets go.
func stick(dir: Vector3) -> void:
	var d := Vector2(dir.x, dir.z)
	if d.length() > 1.0:
		d = d.normalized()
	_axis(&"move_right", maxf(d.x, 0.0))
	_axis(&"move_left", maxf(-d.x, 0.0))
	_axis(&"move_down", maxf(d.y, 0.0))
	_axis(&"move_up", maxf(-d.y, 0.0))


func let_go() -> void:
	stick(Vector3.ZERO)
	for a: StringName in [&"sprint", &"sneak"]:
		Input.action_release(a)


## Walk (or sprint) to `to` on the ground plane; true when within `near` m before `timeout` s.
func walk_to(to: Vector3, sprint: bool = false, near: float = 0.6, timeout: float = 25.0) -> bool:
	if sprint:
		Input.action_press(&"sprint")
	var p := game.player
	var arrived := await s.wait_until(func() -> bool:
		var d := Vector3(to.x - p.global_position.x, 0.0, to.z - p.global_position.z)
		if d.length() <= near:
			return true
		stick(d.normalized())
		# An edge in the way (a hay pile, a crate): the drop intent walks off it.
		if p.state == "edge":
			Input.action_press(&"drop")
		else:
			Input.action_release(&"drop")
		return false, timeout)
	stick(Vector3.ZERO)
	Input.action_release(&"sprint")
	Input.action_release(&"drop")
	return arrived


## Climb the face in front: walk into it along `dir`, jump to grab, hold the stick toward the wall until standing on
## a top (the climber is back to none, the body on a floor above `min_y`).
func climb(dir: Vector3, min_y: float, timeout: float = 30.0) -> bool:
	var p := game.player
	stick(dir)
	await s.wait(0.5)
	await s.tap("jump")
	var up := await s.wait_until(func() -> bool:
		stick(dir)
		return p.climber.state == &"none" and p.is_on_floor() and p.global_position.y >= min_y, timeout)
	stick(Vector3.ZERO)
	return up


## Seconds of `hold` on an action while the stick points at `dir`.
func push(dir: Vector3, seconds: float, hold: StringName = &"") -> void:
	if hold != &"":
		Input.action_press(hold)
	stick(dir)
	await s.wait(seconds)
	stick(Vector3.ZERO)
	if hold != &"":
		Input.action_release(hold)


func _axis(action: StringName, strength: float) -> void:
	if strength > 0.01:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)
