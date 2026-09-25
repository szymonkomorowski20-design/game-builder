extends Node
## Global signal bus used by the recipes (same shape as the game-builder template's Events autoload).

@warning_ignore("unused_signal")
signal game_over(won: bool)
@warning_ignore("unused_signal")
signal damage_dealt(target: Node, amount: int)
@warning_ignore("unused_signal")
signal item_picked(item_id: StringName, amount: int)
