class_name GbScenario
extends Node
## Base class for bot-player scenarios run by the game-builder harness:
##   node tools/gb/gb.js scenario res://tests/scenarios/<name>.gd
##
## Override `run()`. Time is counted in PHYSICS frames, so a scenario plays out identically on every
## run and every machine (physics is deterministic; the harness seeds the RNG).
##
##   func run() -> void:
##       var player := node("Player") as CharacterBody2D
##       var start_x := player.position.x
##       await press("move_right", 1.0)
##       expect_gt(player.position.x, start_x + 50.0, "player walks right")
##       await tap("jump")
##       await wait(0.3)
##       expect_lt(player.position.y, 100.0, "player is in the air after jumping")

var failures: Array[String] = []


## Override in your scenario.
func run() -> void:
	pass


## The GbHarness autoload. Reached by path, not by its global name: autoload names are not
## compiled as identifiers when scripts are loaded outside a running game (gb check, measured on 4.7.2).
func harness() -> Node:
	return get_node("/root/GbHarness")


# ---- time ----

func wait_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func wait(seconds: float) -> void:
	await wait_frames(maxi(1, int(round(seconds * Engine.physics_ticks_per_second))))


## Wait until `predicate` returns true, at most `timeout` seconds. Returns whether it became true.
func wait_until(predicate: Callable, timeout: float = 5.0) -> bool:
	var frames := int(round(timeout * Engine.physics_ticks_per_second))
	for i in frames:
		if predicate.call():
			return true
		await get_tree().physics_frame
	return bool(predicate.call())


# ---- input (project input actions, never raw keys) ----

func hold(action: String) -> void:
	_check_action(action)
	harness().set_action(action, true)


func release(action: String) -> void:
	harness().set_action(action, false)


## Hold an action for `seconds`, then release it.
func press(action: String, seconds: float) -> void:
	hold(action)
	await wait(seconds)
	release(action)


## Press and release on the next frames (a single "just pressed").
func tap(action: String) -> void:
	hold(action)
	await wait_frames(2)
	release(action)
	await wait_frames(1)


func _check_action(action: String) -> void:
	if not InputMap.has_action(action):
		_fail("input action '%s' does not exist in the Input Map" % action)


# ---- scene access ----

## Find a node in the current scene by path ("Player", "World/Enemies/Slime") or, failing that, by name anywhere.
func node(path_or_name: String) -> Node:
	var root := get_tree().current_scene
	if root == null:
		_fail("no current scene")
		return null
	var n := root.get_node_or_null(NodePath(path_or_name))
	if n == null:
		n = root.find_child(path_or_name, true, false)
	if n == null:
		_fail("node '%s' not found in %s" % [path_or_name, root.scene_file_path])
	return n


func nodes_in_group(group: String) -> Array[Node]:
	return get_tree().get_nodes_in_group(group)


func load_scene(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		_fail("cannot change scene to %s (error %d)" % [path, err])
		return
	await get_tree().process_frame
	await get_tree().process_frame


## Screenshot of the current frame (skipped with a note when running headless).
func shot(shot_name: String) -> void:
	await harness().capture(shot_name)


# ---- expectations (collect failures; the scenario keeps running) ----

func expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_fail("%s — expected %s, got %s" % [message, str(expected), str(actual)])


func expect_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) > tolerance:
		_fail("%s — expected %.3f ± %.3f, got %.3f" % [message, expected, tolerance, actual])


func expect_gt(actual: float, bound: float, message: String) -> void:
	if not actual > bound:
		_fail("%s — expected > %.3f, got %.3f" % [message, bound, actual])


func expect_lt(actual: float, bound: float, message: String) -> void:
	if not actual < bound:
		_fail("%s — expected < %.3f, got %.3f" % [message, bound, actual])


func _fail(message: String) -> void:
	failures.append(message)
