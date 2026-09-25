extends GutTest
## R18 — linear advance, conditional choices, flags set on entering, end of conversation, the JSON file parses.


func _guard(flags: Dictionary = {}) -> DialogueRunner:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://18-dialogue/guard.json"))
	return DialogueRunner.new(data, flags)


func test_r18_linear_then_choices() -> void:
	var d := _guard()
	d.start("start")
	assert_eq(d.current().text, "Halt! Nobody enters the castle.")
	d.advance()
	assert_eq(d.current_id, "ask")
	d.advance()
	assert_eq(d.current_id, "ask", "advance ignored while choices are pending")


func test_r18_choices_filtered_by_flags() -> void:
	var d := _guard()
	d.start("ask")
	var texts := d.choices().map(func(c): return c.text)
	assert_eq(texts, ["Offer gold", "Leave"], "no seal → no seal option")
	var with_seal := _guard({"has_seal": true})
	with_seal.start("ask")
	assert_eq(with_seal.choices().size(), 3)


func test_r18_choice_sets_flags_and_ends() -> void:
	var flags := {}
	var d := _guard(flags)
	watch_signals(d)
	d.start("ask")
	d.choose(0)   # Offer gold
	assert_true(flags.get("castle_open", false), "flags shared with the caller")
	d.advance()
	assert_false(d.is_running())
	assert_signal_emitted(d, "ended")
	d.start("ask")
	assert_false(d.choices().any(func(c): return c.text == "Offer gold"), "cannot bribe twice")


func test_r18_leave_ends_immediately() -> void:
	var d := _guard()
	d.start("ask")
	d.choose(1)
	assert_false(d.is_running())
