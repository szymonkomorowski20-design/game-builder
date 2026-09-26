extends Node2D
## Arena controller: waves of enemies from spawn points, heart pickups, HUD, win/lose and restart.
## Observable for tests: `wave`, `enemies_alive`, `kills`, `won`, `lost`, `score`.

const ENEMY := preload("res://scenes/enemies/enemy.tscn")

@export var waves: PackedInt32Array = PackedInt32Array([2, 3])   ## enemies per wave
@export var wave_delay: float = 0.6                               ## s between waves

var wave := 0
var enemies_alive := 0
var kills := 0
var won := false
var lost := false
## "wave/kills/health" — read by the harness (group gb_track) so replays compare it.
var score := ""

var _next_wave_in := -1.0

@onready var player: TopDownPlayer = $Player
@onready var hud_hp: Label = $HUD/Health
@onready var hud_wave: Label = $HUD/Wave
@onready var message: Label = $HUD/Message


func _ready() -> void:
	player.health_changed.connect(func(_h: int, _m: int): _update_hud())
	player.died.connect(_on_player_died)
	for heart in get_tree().get_nodes_in_group("hearts"):
		heart.body_entered.connect(_on_heart_body_entered.bind(heart))
	_start_wave(0)


func _physics_process(delta: float) -> void:
	if _next_wave_in >= 0.0:
		_next_wave_in -= delta
		if _next_wave_in < 0.0:
			_start_wave(wave + 1)
	if (won or lost) and Input.is_action_just_pressed("pause"):
		get_tree().reload_current_scene()


func _start_wave(index: int) -> void:
	wave = index
	var points := $SpawnPoints.get_children()
	for i in waves[index]:
		var e: TopDownEnemy = ENEMY.instantiate()
		e.position = (points[i % points.size()] as Node2D).position
		e.target = player
		e.died.connect(_on_enemy_died)
		$Enemies.add_child(e)
		enemies_alive += 1
	_update_hud()


func _on_enemy_died(_e: TopDownEnemy) -> void:
	enemies_alive -= 1
	kills += 1
	if enemies_alive == 0 and not lost:
		if wave + 1 < waves.size():
			_next_wave_in = wave_delay
		else:
			won = true
			message.text = "Wygrana! Esc — jeszcze raz"
			message.visible = true
			get_node("/root/Events").game_over.emit(true)
	_update_hud()


func _on_player_died() -> void:
	lost = true
	message.text = "Porażka — Esc, aby spróbować ponownie"
	message.visible = true
	get_node("/root/Events").game_over.emit(false)
	_update_hud()


func _on_heart_body_entered(body: Node2D, heart: Area2D) -> void:
	if body != player or heart.is_queued_for_deletion():
		return
	if player.heal(1) > 0:
		heart.queue_free()


func _update_hud() -> void:
	score = "%d/%d/%d" % [wave, kills, player.health]
	hud_hp.text = "Życie: %d/%d" % [player.health, player.tuning.max_health]
	hud_wave.text = "Fala %d/%d · wrogów: %d" % [wave + 1, waves.size(), enemies_alive]
