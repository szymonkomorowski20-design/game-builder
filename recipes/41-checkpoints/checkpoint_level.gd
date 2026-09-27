extends Node2D
## Demo level: a TopDownMover (recipe 01) in group `player`, two checkpoints, a start point. `kill()` stands in for
## whatever kills the player in your game (a hazard, a pit, zero health).

var tracker: CheckpointTracker
var deaths := 0

@onready var player: TopDownMover = $Mover
@onready var checkpoints: Array[Checkpoint] = [$CheckpointA, $CheckpointB]


func _ready() -> void:
	tracker = CheckpointTracker.new(player.global_position)
	for c in checkpoints:
		c.touched.connect(_on_touched)


func _on_touched(c: Checkpoint) -> void:
	if tracker.reach(c.order, c.global_position):
		for other in checkpoints:
			other.set_active(other == c)


func kill() -> void:
	deaths += 1
	player.global_position = tracker.respawn_position
	player.velocity = Vector2.ZERO
