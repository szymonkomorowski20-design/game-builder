class_name LevelSet
extends Resource
## Levels as text inside a Resource (data/levels.tres) — exported with the game. Plain .txt files would be left
## out of the export unless added to the preset's include_filter (gb export --smoke catches that).

## Each level is one string with rows separated by "\n".
@export var levels: PackedStringArray = PackedStringArray()


func rows(index: int) -> PackedStringArray:
	return levels[index].split("\n")


func count() -> int:
	return levels.size()
