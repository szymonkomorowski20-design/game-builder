extends SceneTree
## game-builder: compare two PNG screenshots (runs headless — image maths needs no window).
## User args (after `--`): --a=<abs png> --b=<abs png> --diff=<abs png to write> [--tolerance=0.02]
## A pixel "differs" when any RGBA channel differs by more than `tolerance` (0..1).
## Output: GB_IMGDIFF size_match=<bool> differing=<n> total=<n> ratio=<float>


func _init() -> void:
	var a := {}
	for arg: String in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=", true, 1)
		if kv.size() == 2:
			a[kv[0]] = kv[1]
	var tol := float(a.get("tolerance", "0.02"))
	var ia := Image.load_from_file(String(a.get("a", "")))
	var ib := Image.load_from_file(String(a.get("b", "")))
	if ia == null or ib == null:
		print("GB_IMGDIFF error=cannot_load")
		quit(2)
		return
	ia.convert(Image.FORMAT_RGBA8)
	ib.convert(Image.FORMAT_RGBA8)
	if ia.get_size() != ib.get_size():
		print("GB_IMGDIFF size_match=false a=%s b=%s differing=-1 total=-1 ratio=1.0" % [str(ia.get_size()), str(ib.get_size())])
		quit(1)
		return
	var w := ia.get_width()
	var h := ia.get_height()
	var diff := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var differing := 0
	for y in h:
		for x in w:
			var ca := ia.get_pixel(x, y)
			var cb := ib.get_pixel(x, y)
			var d := maxf(maxf(absf(ca.r - cb.r), absf(ca.g - cb.g)), maxf(absf(ca.b - cb.b), absf(ca.a - cb.a)))
			if d > tol:
				differing += 1
				diff.set_pixel(x, y, Color(1, 0, 0, 1))
			else:
				diff.set_pixel(x, y, Color(ca.r, ca.g, ca.b, 0.25))
	if a.has("diff"):
		diff.save_png(String(a["diff"]))
	var total := w * h
	print("GB_IMGDIFF size_match=true differing=%d total=%d ratio=%.6f" % [differing, total, float(differing) / total])
	quit(0)
