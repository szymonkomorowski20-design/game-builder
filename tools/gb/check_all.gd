extends SceneTree
## game-builder: load every GDScript in the project in ONE engine boot.
## `godot --check-only` checks one file per boot; this checks all of them at once.
## Skips addons/ (third-party code is not the game's defect) and any folder holding .gdignore.
## Output contract read by gb.js: GB_CHECK_OK/FAIL <path> per file, then GB_CHECK_DONE files=N bad=M.


func _walk(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	if d.file_exists(".gdignore"):
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if not n.begins_with("."):
			var p := dir.path_join(n)
			if d.current_is_dir():
				if not (dir == "res://" and n == "addons"):
					_walk(p, out)
			elif n.ends_with(".gd"):
				out.append(p)
		n = d.get_next()
	d.list_dir_end()


func _init() -> void:
	var files: Array = []
	_walk("res://", files)
	files.sort()
	var bad := 0
	for f in files:
		var s = ResourceLoader.load(f, "", ResourceLoader.CACHE_MODE_IGNORE)
		if s == null or not (s is GDScript) or not (s as GDScript).can_instantiate():
			print("GB_CHECK_FAIL ", f)
			bad += 1
		else:
			print("GB_CHECK_OK ", f)
	print("GB_CHECK_DONE files=%d bad=%d" % [files.size(), bad])
	quit(1 if bad > 0 else 0)
