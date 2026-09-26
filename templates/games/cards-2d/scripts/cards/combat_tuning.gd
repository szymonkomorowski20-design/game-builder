class_name CombatTuning
extends Resource
## Every balance number of the card combat (data/combat_tuning.tres).

@export var player_hp: int = 40
@export var energy_per_turn: int = 3
@export var hand_size: int = 5
@export var enemy_hp: int = 30
@export var enemy_intents: PackedInt32Array = PackedInt32Array([6, 8, 12])   ## damage per turn, cycling
@export var seed_value: int = 7                                              ## deck shuffle seed
