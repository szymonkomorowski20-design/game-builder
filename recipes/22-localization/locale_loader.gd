class_name LocaleLoader
extends RefCounted
## Builds Translation objects from a CSV (keys,en,pl,…) at runtime.
## In a real project you add the CSV to the project and Godot's importer generates *.translation files that you register
## in Project Settings → Localization. This loader does the same in code, so tests (and mods) need no import step.
## Empty cells are skipped → TranslationServer falls back to the fallback locale (en).

static func load_csv(path: String) -> Array[Translation]:
	var f := FileAccess.open(path, FileAccess.READ)
	var header := f.get_csv_line()
	var out: Array[Translation] = []
	for col in range(1, header.size()):
		var t := Translation.new()
		t.locale = header[col]
		out.append(t)
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < 2 or row[0] == "":
			continue
		for col in range(1, mini(row.size(), header.size())):
			if row[col] != "":
				out[col - 1].add_message(row[0], row[col])
	return out
