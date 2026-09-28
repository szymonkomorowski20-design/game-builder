extends Node
## game-builder test harness (autoload "GbHarness").
##
## INERT in normal play: it does nothing unless the game is started with `--gb-*` user arguments
## (after `--` on the Godot command line). `node tools/gb/gb.js` passes them; players never do.
##
##   --gb-seed=N            seed the global RNG (randi/randf) — default 12345 whenever the harness is active
##   --gb-out=<abs dir>     where records, shots and perf reports are written
##   --gb-scenario=res://…  run a GbScenario script (bot player with expectations), then quit
##   --gb-record=<name>     record the project's input actions per physics frame (human plays; saved on exit)
##   --gb-replay=<abs file> replay a recording frame by frame, then quit
##   --gb-shot=60:title,120:after   capture the viewport at render frames (needs a window, not --headless)
##   --gb-perf=<name>       sample Performance monitors every frame; summary written on exit
##   --gb-end-shot          after a scenario, capture its final frame as <scenario>__end (evidence, not a baseline)
##
## Output contract (read by gb.js): lines starting with GB_ on stdout.
## Measured on Godot 4.7.2: physics is deterministic across runs; the global RNG is not unless seeded;
## Input.action_press / parse_input_event work under --headless; viewport capture needs a window.

const RECORD_VERSION := 1

var args: Dictionary = {}
var active := false
var out_dir := ""
var seed_value := 0

var _physics_frame := 0
var _render_frame := 0
var _recording := false
var _record_events: Array = []
var _prev_pressed: Dictionary = {}
var _replay_events: Array = []
var _replay_index := 0
var _replay_last_frame := -1
var _shots: Dictionary = {}
var _perf := false
var _perf_samples: Array = []
var _finished := false
var _last_signature := ""
var _expected_signature := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = -1000
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--gb-"):
			var kv := a.substr(5).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	active = not args.is_empty()
	if not active:
		set_process(false)
		set_physics_process(false)
		return
	out_dir = String(args.get("out", OS.get_user_data_dir()))
	DirAccess.make_dir_recursive_absolute(out_dir)
	seed_value = int(args.get("seed", "12345"))
	seed(seed_value)
	print("GB_HARNESS active seed=%d headless=%s" % [seed_value, str(is_headless())])
	_recording = args.has("record")
	_perf = args.has("perf")
	if args.has("replay"):
		_load_replay(String(args["replay"]))
	if args.has("shot"):
		for part: String in String(args["shot"]).split(","):
			var fp := part.split(":")
			if fp.size() == 2:
				_shots[int(fp[0])] = fp[1]
	if args.has("scenario"):
		_run_scenario.call_deferred(String(args["scenario"]))


func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


func project_actions() -> Array:
	var out: Array = []
	for a: StringName in InputMap.get_actions():
		if not String(a).begins_with("ui_"):
			out.append(String(a))
	return out


func set_action(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


## Deterministic fingerprint of the nodes in group "gb_track" (add your player/enemies/score holder to it).
## Recorded at the end of a recording; a replay must reproduce it exactly.
func state_signature() -> String:
	var parts: PackedStringArray = []
	var tracked := get_tree().get_nodes_in_group("gb_track")
	tracked.sort_custom(func(a: Node, b: Node) -> bool: return str(a.get_path()) < str(b.get_path()))
	for n: Node in tracked:
		var s := str(n.get_path())
		if n is Node2D:
			s += " p=%.2f,%.2f" % [n.global_position.x, n.global_position.y]
		elif n is Node3D:
			s += " p=%.2f,%.2f,%.2f" % [n.global_position.x, n.global_position.y, n.global_position.z]
		for prop: String in ["health", "hp", "score", "state"]:
			if prop in n:
				s += " %s=%s" % [prop, str(n.get(prop))]
		parts.append(s)
	return "; ".join(parts)


func _physics_process(_delta: float) -> void:
	_physics_frame += 1
	if _recording:
		_last_signature = state_signature()
	if _replay_events.size() > 0 or _replay_last_frame > 0:
		while _replay_index < _replay_events.size() and int(_replay_events[_replay_index][0]) <= _physics_frame:
			var e: Array = _replay_events[_replay_index]
			set_action(String(e[1]), bool(e[2]))
			_replay_index += 1
		if _physics_frame >= _replay_last_frame and not _finished:
			var actual := state_signature()
			var matched := _expected_signature == "" or actual == _expected_signature
			print("GB_REPLAY_DONE frames=%d events=%d tracked=%s match=%s" % [_physics_frame, _replay_events.size(), str(_expected_signature != ""), str(matched)])
			if not matched:
				print("GB_REPLAY_EXPECTED ", _expected_signature)
				print("GB_REPLAY_ACTUAL   ", actual)
			finish(0 if matched else 1)
	if _recording:
		for a: String in project_actions():
			var p := Input.is_action_pressed(a)
			if p != bool(_prev_pressed.get(a, false)):
				_record_events.append([_physics_frame, a, p])
				_prev_pressed[a] = p


const PERF_WARMUP_FRAMES := 30
const PERF_WARMUP_SECONDS := 1.0   ## and at least this much time: at 500 fps, 30 frames are the scene still loading
var _perf_time := 0.0


func _process(delta: float) -> void:
	_render_frame += 1
	_perf_time += delta
	if _perf and _render_frame > PERF_WARMUP_FRAMES and _perf_time > PERF_WARMUP_SECONDS:
		_perf_samples.append([
			delta * 1000.0,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		])
	if _shots.has(_render_frame):
		capture(String(_shots[_render_frame]))


## Save the viewport as <out>/<name>.png. Returns the path, or "" when there is nothing to capture.
func capture(shot_name: String) -> String:
	if is_headless():
		print("GB_SHOT_SKIP name=%s reason=headless" % shot_name)
		return ""
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		print("GB_SHOT_SKIP name=%s reason=empty" % shot_name)
		return ""
	var path := out_dir.path_join(shot_name + ".png")
	var err := img.save_png(path)
	print("GB_SHOT name=%s path=%s size=%dx%d err=%d" % [shot_name, path, img.get_width(), img.get_height(), err])
	return path


func _load_replay(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY or not data.has("events"):
		print("GB_REPLAY_ERROR cannot read %s" % path)
		finish(1)
		return
	_replay_events = data["events"]
	_replay_last_frame = int(data.get("frames", 0))
	_expected_signature = String(data.get("final_state", ""))
	if data.has("seed"):
		seed_value = int(data["seed"])
		seed(seed_value)
	print("GB_REPLAY_START events=%d frames=%d seed=%d" % [_replay_events.size(), _replay_last_frame, seed_value])


func _run_scenario(path: String) -> void:
	var script := load(path) as Script
	# A script with a parse error still loads as a Script object, but cannot be instantiated; fail now instead of
	# waiting for the frame cap.
	if script == null or not script.can_instantiate():
		print("GB_SCENARIO name=%s result=FAIL failures=1" % path)
		print("GB_EXPECT_FAIL could not load scenario script (parse error? see the SCRIPT ERROR lines)")
		finish(1)
		return
	var sc: Node = script.new()
	sc.name = "GbScenario"
	add_child(sc)
	await get_tree().process_frame
	await sc.run()
	if args.has("end-shot"):
		await capture(path.get_file().get_basename() + "__end")
	var failures: Array = sc.failures
	print("GB_SCENARIO name=%s result=%s failures=%d frames=%d" % [path, "PASS" if failures.is_empty() else "FAIL", failures.size(), _physics_frame])
	for f: String in failures:
		print("GB_EXPECT_FAIL ", f)
	finish(0 if failures.is_empty() else 1)


func finish(code: int) -> void:
	if _finished:
		return
	_finished = true
	_write_outputs()
	get_tree().quit(code)


func _exit_tree() -> void:
	if active:
		_write_outputs()


var _written := false


func _write_outputs() -> void:
	if _written:
		return
	_written = true
	if _recording:
		var rec := {
			"version": RECORD_VERSION,
			"godot": Engine.get_version_info().string,
			"scene": get_tree().current_scene.scene_file_path if get_tree().current_scene else "",
			"seed": seed_value,
			"physics_ticks": Engine.physics_ticks_per_second,
			"frames": _physics_frame,
			"events": _record_events,
			"final_state": _last_signature,
		}
		var rpath := out_dir.path_join(String(args["record"]) + ".json")
		var f := FileAccess.open(rpath, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(rec, "  "))
			f.close()
			print("GB_RECORD path=%s events=%d frames=%d" % [rpath, _record_events.size(), _physics_frame])
	if _perf and _perf_samples.size() > 0:
		var summary := _perf_summary()
		var ppath := out_dir.path_join(String(args["perf"]) + ".json")
		var pf := FileAccess.open(ppath, FileAccess.WRITE)
		if pf:
			pf.store_string(JSON.stringify(summary, "  "))
			pf.close()
			print("GB_PERF path=%s frames=%d" % [ppath, _perf_samples.size()])


func _perf_summary() -> Dictionary:
	var cols := ["frame_ms", "process_ms", "physics_ms", "draw_calls", "nodes", "static_memory_mb"]
	var out := {"frames": _perf_samples.size(), "warmup_frames_skipped": PERF_WARMUP_FRAMES, "warmup_seconds_skipped": PERF_WARMUP_SECONDS, "headless": is_headless()}
	for c in range(cols.size()):
		var vals: Array = []
		for s: Array in _perf_samples:
			vals.append(float(s[c]))
		vals.sort()
		var total := 0.0
		for v: float in vals:
			total += v
		out[cols[c]] = {
			"avg": total / vals.size(),
			"p95": vals[int(floor((vals.size() - 1) * 0.95))],
			"max": vals[vals.size() - 1],
			"min": vals[0],
		}
	return out
