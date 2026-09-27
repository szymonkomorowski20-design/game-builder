class_name SaveSystem
extends RefCounted
## Versioned JSON saves with migrations and atomic writes.
## - Every save carries `version`. Loading an older version runs the migrations in order.
## - Writing goes to <file>.tmp first, then renames — a crash mid-write never destroys the last good save.
## - A corrupt or future-version file is reported, never silently replaced by defaults.

const CURRENT_VERSION := 2

enum Result { OK, MISSING, CORRUPT, TOO_NEW }


## Migrations: index n migrates version n → n+1.
static func _migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 1))
	if v < 2:
		# v1 stored "gold" at the top level; v2 moved it into "player" and renamed it "coins".
		var player: Dictionary = data.get("player", {})
		player["coins"] = int(data.get("gold", 0))
		data.erase("gold")
		data["player"] = player
		v = 2
	data["version"] = v
	return data


static func save(path: String, data: Dictionary) -> Error:
	var copy := data.duplicate(true)
	copy["version"] = CURRENT_VERSION
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(copy, "  "))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp, path)


## Returns {"result": Result, "data": Dictionary}
## An interrupted save can leave <path>.tmp behind:
## - the save is gone (the crash hit between removing the old file and renaming the new one) → the .tmp is the newest
##   complete write: it is renamed into place and loaded — unless it is itself unfinished (corrupt), then it is dropped;
## - the save is still there → the .tmp is an unfinished write and is dropped; the last good save stays.
static func load_save(path: String) -> Dictionary:
	var tmp := path + ".tmp"
	if FileAccess.file_exists(tmp):
		if FileAccess.file_exists(path) or _read(tmp).result == Result.CORRUPT:
			DirAccess.remove_absolute(tmp)
		else:
			DirAccess.rename_absolute(tmp, path)
	return _read(path)


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"result": Result.MISSING, "data": {}}
	# JSON instance, not JSON.parse_string: a corrupt save is an expected case, not an engine error to print.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {"result": Result.CORRUPT, "data": {}}
	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"result": Result.CORRUPT, "data": {}}
	var v := int(parsed.get("version", 1))
	if v > CURRENT_VERSION:
		return {"result": Result.TOO_NEW, "data": {}}
	return {"result": Result.OK, "data": _migrate(parsed)}
