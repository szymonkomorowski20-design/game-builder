class_name RunDemo
extends Control
## A run loop without the fighting: pick a door (move_left / move_right, action), the room "resolves" (a currency
## door pays 12, any other room 5), `jump` = die. In the hub, action buys +10 max health, jump starts a new run.
## Shows that death banks the run's currency and the next run starts stronger.

var map := RunMap.new()
var run := RunState.new()
var meta := MetaProgress.new()
var sheet := StatSheet.new({&"max_health": 50.0})
var doors: Array[RoomDoor] = []
var selected := 0
var in_hub := false
var runs := 0

@onready var _label := $Info as Label


func _ready() -> void:
	meta.upgrades = {&"vitality": {"stat": &"max_health", "per_level": 10.0, "base_cost": 10, "max_level": 5}}
	_new_run()


func _unhandled_input(event: InputEvent) -> void:
	if in_hub:
		if event.is_action_pressed(&"action"):
			meta.buy(&"vitality")
		elif event.is_action_pressed(&"jump"):
			_new_run()
		_show()
		return
	if event.is_action_pressed(&"move_left"):
		selected = wrapi(selected - 1, 0, doors.size())
	elif event.is_action_pressed(&"move_right"):
		selected = wrapi(selected + 1, 0, doors.size())
	elif event.is_action_pressed(&"action"):
		_enter(doors[selected])
	elif event.is_action_pressed(&"jump"):
		_to_hub(false)
	_show()


func _new_run() -> void:
	runs += 1
	run.begin(1000 + runs)
	meta.apply_to(sheet)
	in_hub = false
	_deal()


func _enter(door: RoomDoor) -> void:
	run.enter(door)
	run.collect(12 if door.reward == RoomDoor.Reward.CURRENCY else 5)
	if door.type == RoomDoor.Type.BOSS:
		_to_hub(true)
	else:
		_deal()


func _to_hub(won: bool) -> void:
	meta.bank(run.end(won))
	in_hub = true


func _deal() -> void:
	doors = map.doors(run.depth, run.seed, run.previous_type())
	selected = 0
	_show()


func _show() -> void:
	if in_hub:
		_label.text = "HUB — currency %d · vitality lv %d (next %d) · max health %.0f\naction: buy · jump: new run" % [
			meta.currency, meta.level(&"vitality"), meta.cost(&"vitality"), sheet.value(&"max_health")]
		return
	var lines := PackedStringArray()
	for i in doors.size():
		lines.append(("> " if i == selected else "  ") + doors[i].label())
	_label.text = "Run %d · room %d/%d · collected %d · max health %.0f\n%s\njump: die" % [
		runs, run.depth + 1, map.rooms, run.collected, sheet.value(&"max_health"), "\n".join(lines)]
