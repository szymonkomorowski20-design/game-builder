extends Node
## The performance scene (spec: Performance budget — "the heaviest moment: two full armies fighting in the middle of
## the map, fog on, everything in view", vsync off). Each side is topped up to 40 units every few seconds (a max-supply
## army of footmen, archers and riders), so the whole measurement is the battle. Run it with
##   node tools/gb/gb.js perf --scene res://tests/fixtures/perf_battle.tscn --seconds 120

const SKIRMISH := preload("res://scenes/skirmish/skirmish.tscn")
const MIX: Array[StringName] = [&"footman", &"footman", &"archer", &"archer", &"rider"]
const PER_SIDE := 40
const SPAWN_PER_TICK := 1                    ## a barracks trains one at a time; the fixture tops up one per side a tick
const MIDDLE := Vector3(0, 0, 16)           ## open ground between the rocks (the centre rock sits at 0, 0, 0)

var game: RtsGame
var _top_up := 0.0


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game = SKIRMISH.instantiate() as RtsGame
	game.ai_enabled = false
	game.reveal_map = true
	add_child(game)
	(game.get_node("CameraRig") as RtsCamera).jump_to(MIDDLE)


func _physics_process(delta: float) -> void:
	_top_up -= delta
	if _top_up > 0.0:
		return
	var made := 0
	for t in 2:
		var side := game.units.filter(func(u: RtsUnit) -> bool: return u.team == t and u.kind != &"worker")
		var dir := 1.0 if t == 0 else -1.0
		for i in mini(PER_SIDE - side.size(), SPAWN_PER_TICK):
			made += 1
			var k := side.size() + i                  # the next spot of a 5 × 8 block (its first units have marched off)
			var at := MIDDLE + Vector3(-(10.0 + (k / 8) * 1.4) * dir, 0, -3.5 + (k % 8) * 1.4)
			var u := game.spawn_unit(t, MIX[k % MIX.size()], at)
			u.orders.give(RtsOrders.make(RtsOrders.Kind.ATTACK_MOVE, MIDDLE + Vector3(14.0 * dir, 0, 0)))
	if made == 0:
		_top_up = 4.0                            # both sides full: look again in a few seconds
