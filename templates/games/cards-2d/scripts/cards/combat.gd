class_name Combat
extends RefCounted
## Turn-based card combat as a pure model: energy, hand, block, enemy intents, win/lose. The view only displays
## it and forwards input; every rule is testable without a scene.

signal changed
signal ended(won: bool)

var cards: CardSet
var tuning: CombatTuning
var deck: Deck
var player_hp := 0
var block := 0
var energy := 0
var enemy_hp := 0
var turn := 0
var intent_index := 0
var over := false
var won := false


func _init(card_set: CardSet, combat_tuning: CombatTuning) -> void:
	cards = card_set
	tuning = combat_tuning
	deck = Deck.new(Array(cards.starting_deck), tuning.seed_value)
	player_hp = tuning.player_hp
	enemy_hp = tuning.enemy_hp
	_start_turn()


func intent() -> int:
	return tuning.enemy_intents[intent_index % tuning.enemy_intents.size()]


func can_play(index: int) -> bool:
	return not over and index >= 0 and index < deck.hand.size() and cards.cost(deck.hand[index]) <= energy


## Plays the card at `index` in the hand. Returns false (nothing changes) when it can't be played.
func play(index: int) -> bool:
	if not can_play(index):
		return false
	var id: String = deck.hand[index]
	energy -= cards.cost(id)
	deck.play(index)
	enemy_hp = maxi(enemy_hp - cards.damage(id), 0)
	block += cards.block(id)
	if enemy_hp == 0:
		_finish(true)
	changed.emit()
	return true


## Enemy acts (its intent minus the player's block), the hand is discarded, a new turn starts.
func end_turn() -> void:
	if over:
		return
	var dmg := intent()
	var absorbed := mini(block, dmg)
	player_hp = maxi(player_hp - (dmg - absorbed), 0)
	intent_index += 1
	deck.discard_hand()
	if player_hp == 0:
		_finish(false)
	else:
		_start_turn()
	changed.emit()


func _start_turn() -> void:
	turn += 1
	energy = tuning.energy_per_turn
	block = 0
	deck.draw(tuning.hand_size)


func _finish(player_won: bool) -> void:
	over = true
	won = player_won
	ended.emit(player_won)
