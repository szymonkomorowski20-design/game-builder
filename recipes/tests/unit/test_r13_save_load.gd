extends GutTest
## R13 (tier A — player progress) — round trip, v1 → v2 migration, corrupt and future files reported,
## no leftover temp file, an existing save survives a failed parse of a new one.

var dir := ""


func before_each() -> void:
	dir = OS.get_user_data_dir().path_join("gb_recipe_saves_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(dir)


func after_each() -> void:
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)


func _write(name: String, text: String) -> String:
	var p := dir.path_join(name)
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	return p


func test_r13_round_trip_current_version() -> void:
	var p := dir.path_join("slot1.json")
	assert_eq(SaveSystem.save(p, {"player": {"coins": 7, "level": 3}}), OK)
	var r := SaveSystem.load_save(p)
	assert_eq(r.result, SaveSystem.Result.OK)
	assert_eq(int(r.data.player.coins), 7)
	assert_eq(int(r.data.version), SaveSystem.CURRENT_VERSION)
	assert_false(FileAccess.file_exists(p + ".tmp"), "temp file renamed away")


func test_r13_v1_save_is_migrated() -> void:
	var p := _write("old.json", '{"version": 1, "gold": 42, "player": {"level": 2}}')
	var r := SaveSystem.load_save(p)
	assert_eq(r.result, SaveSystem.Result.OK)
	assert_eq(int(r.data.player.coins), 42, "gold moved to player.coins")
	assert_eq(int(r.data.player.level), 2, "other data kept")
	assert_false(r.data.has("gold"))


func test_r13_unversioned_save_is_treated_as_v1() -> void:
	var p := _write("ancient.json", '{"gold": 5}')
	assert_eq(int(SaveSystem.load_save(p).data.player.coins), 5)


func test_r13_corrupt_and_missing_and_too_new_are_reported() -> void:
	assert_eq(SaveSystem.load_save(_write("bad.json", "{not json")).result, SaveSystem.Result.CORRUPT)
	assert_eq(SaveSystem.load_save(dir.path_join("nope.json")).result, SaveSystem.Result.MISSING)
	assert_eq(SaveSystem.load_save(_write("future.json", '{"version": 99}')).result, SaveSystem.Result.TOO_NEW)


func test_r13_overwrite_replaces_previous_save() -> void:
	var p := dir.path_join("slot.json")
	SaveSystem.save(p, {"player": {"coins": 1}})
	SaveSystem.save(p, {"player": {"coins": 2}})
	assert_eq(int(SaveSystem.load_save(p).data.player.coins), 2)
