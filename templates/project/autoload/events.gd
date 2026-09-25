extends Node
## Global signal bus (autoload "Events"). Systems that should not know about each other talk
## through signals declared here, e.g. `Events.player_died.emit()` / `Events.player_died.connect(...)`.
## Declare a signal here only when two unrelated scenes need it; local signals stay local.

@warning_ignore("unused_signal")
signal game_started
@warning_ignore("unused_signal")
signal game_over(won: bool)
