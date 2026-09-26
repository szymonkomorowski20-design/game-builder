extends Control
## Shows a Combat and turns input into moves. Keyboard/gamepad: move_left/move_right select a card, action plays it,
## jump ends the turn (pause restarts after the fight). Mouse: click a card to play it, the button ends the turn.
## Observable for tests: `combat`, `selected`, `score`.

@export var card_set: CardSet = preload("res://data/cards.tres")
@export var tuning: CombatTuning = preload("res://data/combat_tuning.tres")

var combat: Combat
var selected := 0
## "turn/player_hp/enemy_hp" — read by the harness (group gb_track) so replays compare it.
var score := ""

@onready var hand_box: HBoxContainer = $Hand
@onready var player_label: Label = $PlayerInfo
@onready var enemy_label: Label = $EnemyInfo
@onready var message: Label = $Message
@onready var end_turn_button: Button = $EndTurn


func _ready() -> void:
	end_turn_button.pressed.connect(_on_end_turn)
	_new_combat()


func _new_combat() -> void:
	combat = Combat.new(card_set, tuning)
	combat.changed.connect(_refresh)
	combat.ended.connect(_on_ended)
	selected = 0
	message.visible = false
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if combat.over:
		if event.is_action_pressed("pause"):
			_new_combat()
		return
	if event.is_action_pressed("move_left"):
		selected = maxi(selected - 1, 0)
		_refresh()
	elif event.is_action_pressed("move_right"):
		selected = mini(selected + 1, combat.deck.hand.size() - 1)
		_refresh()
	elif event.is_action_pressed("action"):
		_play(selected)
	elif event.is_action_pressed("jump"):
		_on_end_turn()


func _play(index: int) -> void:
	if not combat.play(index):
		_flash("Za mało energii")
		return
	selected = clampi(selected, 0, maxi(combat.deck.hand.size() - 1, 0))


func _on_end_turn() -> void:
	combat.end_turn()
	selected = 0


func _on_ended(won: bool) -> void:
	message.text = ("Wygrana!" if won else "Porażka") + "\nEsc — nowa walka"
	message.visible = true
	get_node("/root/Events").game_over.emit(won)


func _flash(text: String) -> void:
	message.text = text
	message.visible = true


func _refresh() -> void:
	score = "%d/%d/%d" % [combat.turn, combat.player_hp, combat.enemy_hp]
	player_label.text = "Ty: %d/%d HP · blok %d · energia %d/%d" % [combat.player_hp, tuning.player_hp, combat.block, combat.energy, tuning.energy_per_turn]
	enemy_label.text = "Przeciwnik: %d/%d HP · zamierza zadać %d" % [combat.enemy_hp, tuning.enemy_hp, combat.intent()]
	for child in hand_box.get_children():
		child.queue_free()
	for i in combat.deck.hand.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 110)
		# The selection is marked by a symbol, not by colour alone (game-ui-accessibility).
		b.text = ("▶ " if i == selected else "") + card_set.label(combat.deck.hand[i])
		b.disabled = not combat.can_play(i)
		b.modulate = Color(1.0, 0.95, 0.6) if i == selected else Color.WHITE
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_play.bind(i))
		hand_box.add_child(b)
	if not combat.over and message.text == "Za mało energii":
		message.visible = false
