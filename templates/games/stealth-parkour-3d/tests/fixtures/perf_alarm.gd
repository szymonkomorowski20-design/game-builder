extends Node
## Performance fixture (template stealth-parkour-3d): the district at its busiest. A second in, every guard has
## detected the player standing in the square (they hunt, path and fight), and the crowd panics. Measure it with
## gb perf --scene res://tests/fixtures/perf_alarm.tscn --seconds 120 (the budget is .ai/perf-budget.json).

var _armed := false
var _game: StealthGame


func _ready() -> void:
	_game = (load("res://scenes/district/district.tscn") as PackedScene).instantiate() as StealthGame
	add_child(_game)


func _physics_process(_delta: float) -> void:
	if _armed or _game.clock < 1.0:
		return
	_armed = true
	_game.player.teleport(Vector3(15, 0.05, 15))
	_game.player.max_health = 1000000
	_game.player.health = 1000000
	for g in _game.guards:
		g.senses.meter.value = 1.0
		g.senses.meter.detected = true
	for c in _game.civilians:
		c.mind.stimulate(CrowdMind.Mood.PANIC, Vector3(15, 0, 15), _game.clock)
