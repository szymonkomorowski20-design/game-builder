extends SceneTree
## game-builder: change project.godot through the engine (so the file is always written in the
## format THIS Godot version expects). Idempotent.
## User args: --autoload=Name=res://path.gd      register an autoload (singleton) if absent
##            --enable-plugin=res://addons/x/plugin.cfg   add to editor_plugins/enabled if absent
## Output: GB_SETTING changed=<n> err=<code>


func _init() -> void:
	var changed := 0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--autoload="):
			var kv := arg.trim_prefix("--autoload=").split("=", true, 1)
			var key := "autoload/" + kv[0]
			if not ProjectSettings.has_setting(key):
				ProjectSettings.set_setting(key, "*" + kv[1])
				changed += 1
		elif arg.begins_with("--enable-plugin="):
			var cfg := arg.trim_prefix("--enable-plugin=")
			var list: PackedStringArray = ProjectSettings.get_setting("editor_plugins/enabled", PackedStringArray())
			if not list.has(cfg):
				list.append(cfg)
				ProjectSettings.set_setting("editor_plugins/enabled", list)
				changed += 1
	var err := OK
	if changed > 0:
		err = ProjectSettings.save()
	print("GB_SETTING changed=%d err=%d" % [changed, err])
	quit(0 if err == OK else 1)
