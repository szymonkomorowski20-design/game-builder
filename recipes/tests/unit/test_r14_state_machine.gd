extends GutTest
## R14 — initial state entered, exit-before-enter order, message passed, only the active state updates,
## unknown state rejected without changing anything.

var trace: Array = []


class Rec extends State:
	var trace: Array
	var updates := 0

	func enter(msg: Dictionary) -> void:
		trace.append("enter:%s:%s" % [name, msg.get("from", "")])

	func exit() -> void:
		trace.append("exit:%s" % name)

	func physics_update(_delta: float) -> void:
		updates += 1


func _machine() -> StateMachine:
	trace = []
	var m := StateMachine.new()
	for n in ["Idle", "Run"]:
		var s := Rec.new()
		s.name = n
		s.trace = trace
		m.add_child(s)
	add_child_autofree(m)
	return m


func test_r14_first_state_entered_on_ready() -> void:
	var m := _machine()
	assert_eq(m.current.name, "Idle")
	assert_eq(trace, ["enter:Idle:"])


func test_r14_transition_exits_then_enters_with_message() -> void:
	var m := _machine()
	watch_signals(m)
	assert_true(m.transition_to(&"Run", {"from": "idle"}))
	assert_eq(trace, ["enter:Idle:", "exit:Idle", "enter:Run:idle"])
	assert_signal_emitted_with_parameters(m, "transitioned", [&"Idle", &"Run"])


func test_r14_only_active_state_updates() -> void:
	var m := _machine()
	m.set_physics_process(false)   # drive frames by hand, no engine ticks in between
	m._physics_process(0.016)
	m._physics_process(0.016)
	assert_eq((m.states[&"Idle"] as Rec).updates, 2)
	assert_eq((m.states[&"Run"] as Rec).updates, 0)


func test_r14_unknown_state_is_rejected() -> void:
	var m := _machine()
	assert_false(m.transition_to(&"Flying"))
	assert_eq(m.current.name, "Idle")
	assert_eq(trace.size(), 1)
