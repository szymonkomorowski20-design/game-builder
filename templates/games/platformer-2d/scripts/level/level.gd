extends Node2D
## Level controller: coins, falling out of the level (respawn), reaching the goal.

@export var kill_y: float = 480.0   ## px — below this the player respawns

var coins_total: int = 0
var coins_collected: int = 0
var deaths: int = 0
var completed: bool = false
## "collected/total" — read by the harness (group gb_track) so replays compare it.
var score: String = "0/0"

@onready var player: Player = $Player
@onready var spawn: Marker2D = $Spawn
@onready var coin_label: Label = $HUD/Coins
@onready var message: Label = $HUD/Message


func _ready() -> void:
	for coin in get_tree().get_nodes_in_group("coins"):
		coins_total += 1
		coin.body_entered.connect(_on_coin_body_entered.bind(coin))
	$Goal.body_entered.connect(_on_goal_body_entered)
	player.teleport(spawn.global_position)
	_update_hud()


func _physics_process(_delta: float) -> void:
	if player.global_position.y > kill_y:
		deaths += 1
		player.teleport(spawn.global_position)
	if completed and Input.is_action_just_pressed("action"):
		get_tree().reload_current_scene()


func _on_coin_body_entered(body: Node2D, coin: Area2D) -> void:
	if body != player or coin.is_queued_for_deletion():
		return
	coins_collected += 1
	coin.queue_free()
	_update_hud()


func _on_goal_body_entered(body: Node2D) -> void:
	if body != player or completed:
		return
	completed = true
	# Freeze the player at the goal: without this, a held direction walked them off the end of the
	# level after finishing (seen in the level_complete screenshot of scenario p8).
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	message.text = "Meta! Monety: %d/%d\nE / Enter — jeszcze raz" % [coins_collected, coins_total]
	message.visible = true
	get_node("/root/Events").game_over.emit(true)


func _update_hud() -> void:
	score = "%d/%d" % [coins_collected, coins_total]
	coin_label.text = "Monety: " + score
