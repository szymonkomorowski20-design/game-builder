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


## _initialize, not _init: autoload names (Events, GbHarness…) are only known to the compiler after the main loop
## starts — checking in _init reports every script that uses an autoload as broken (measured 2026-09-27).
func _initialize() -> void:
	var files: Array = []
	_walk("res://", files)
	# Never load this checker itself: re-loading the running SceneTree script (a project copy of
	# tools/gb without its .gdignore) hangs or crashes Godot 4.7.2 — measured 2026-09-25.
	var own_path: String = get_script().resource_path
	files = files.filter(func(f: String) -> bool: return f != own_path and not f.begins_with("res://tools/gb/"))
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
