class_name EnemyKind
extends Resource
## One enemy type as the director sees it: what it costs out of a wave's budget, from which depth it may appear,
## and the scene the host spawns.

@export var id: StringName = &""
@export var cost := 1              ## threat points; a rusher 1, a ranged 2, a tank 4…
@export var min_depth := 0         ## first room index where it can appear
@export var scene: PackedScene
