class_name RtsHud
extends CanvasLayer
## The skirmish HUD, drawn in code (placeholder look): resources and food at the top; the player's messages ("Za mało
## surowców", "Jesteśmy atakowani!"); the drag box; selection rings and health bars over units and buildings; the
## selection panel; the command card with keys, costs and what is missing; a building's queue with its progress; a
## minimap with the fog, dots and the camera's view (click it to jump); the end screen.
## Observable: top_text(), message_text, card_text(), minimap_rect.

const BAR_W := 36.0

var game: RtsGame
var input: RtsPlayerInput
var message_text := ""
var minimap_rect := Rect2()

var _message_left := 0.0
var _canvas: Control
var _top: Label
var _msg: Label
var _panel: Label
var _card: Label
var _end: Label
var _fog_tex: ImageTexture
var _fog_t := 0.0


func _ready() -> void:
	game = get_parent() as RtsGame
	if not game.is_node_ready():
		await game.ready
	input = game.get_node(^"PlayerInput") as RtsPlayerInput
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_world)
	add_child(_canvas)
	_top = _label(Vector2(16, 10), 20)
	_msg = _label(Vector2(0, 46), 22, HORIZONTAL_ALIGNMENT_CENTER)
	_panel = _label(Vector2(200, -120), 18)
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_panel.position = Vector2(200, -130)
	_card = _label(Vector2(-460, -150), 18)
	_card.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_card.position = Vector2(-470, -160)
	_end = _label(Vector2(0, -60), 44, HORIZONTAL_ALIGNMENT_CENTER)
	_end.set_anchors_preset(Control.PRESET_CENTER)
	_end.position = Vector2(-450, -60)
	_end.visible = false
	var hint := _label(Vector2(0, -26), 14, HORIZONTAL_ALIGNMENT_CENTER)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-450, -26)
	hint.text = "LPM zaznacz · przeciągnij: ramka · PPM rozkaz · Shift kolejka · A atak w marszu · S stop · B buduj · Q W E R karta · Ctrl+1–9 grupy · strzałki kamera"
	hint.modulate = Color(1, 1, 1, 0.7)
	game.message.connect(_on_message)
	game.game_over.connect(_on_game_over)
	_fog_tex = ImageTexture.create_from_image(_fog_alpha())


func _label(at: Vector2, size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.position = at
	l.size = Vector2(900, size * 5)
	l.horizontal_alignment = align
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override(&"outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		l.set_anchors_preset(Control.PRESET_CENTER_TOP)
		l.position = Vector2(-450, at.y)
	_canvas.add_child(l)
	return l


func _on_message(text: String) -> void:
	message_text = text
	_message_left = 3.0


func _on_game_over(w: int) -> void:
	_end.visible = true
	_end.text = ("Zwycięstwo!" if w == 0 else "Porażka") + "\nCzas: %d:%02d" % [floori(game.elapsed / 60.0), int(game.elapsed) % 60]


func top_text() -> String:
	var s := game.stockpile(0)
	return "Złoto: %d     Drewno: %d     Żywność: %d / %d" % [s.amount(&"gold"), s.amount(&"wood"), s.supply_used, mini(s.supply_cap, s.max_supply)]


func card_text() -> String:
	var lines: Array[String] = []
	for e in input.card():
		var cost: Dictionary = e.cost
		var parts: Array[String] = []
		for k in cost:
			parts.append("%d %s" % [cost[k], "zł." if k == &"gold" else "dr."])
		var line := "[%s] %s — %s" % [e.key, game.name_of(e.kind), ", ".join(parts)]
		if not e.enabled:
			line += "  (%s)" % e.why
		lines.append(line)
	if input.mode == &"place":
		lines.append("Stawianie: %s%s" % [game.name_of(input.placing), "" if input.ghost_why == "" else " — tu nie"])
	elif input.mode == &"attack_move":
		lines.append("Atak w marszu: kliknij cel")
	elif input.mode == &"build_card":
		lines.append("Wybierz budynek (Q W E R)")
	return "\n".join(lines)


func _process(delta: float) -> void:
	_message_left = maxf(_message_left - delta, 0.0)
	if _message_left <= 0.0:
		message_text = ""
	_top.text = top_text()
	_msg.text = message_text
	_panel.text = _panel_text()
	_card.text = card_text()
	_fog_t -= delta
	if _fog_t <= 0.0:
		_fog_t = 0.25
		_fog_tex.update(_fog_alpha())
	_canvas.queue_redraw()


## The fog as black with alpha (unexplored opaque, explored half, visible clear) for the minimap.
func _fog_alpha() -> Image:
	var fog := game.fog(0)
	var src := fog.to_image().get_data()
	var out := PackedByteArray()
	out.resize(src.size() * 2)
	for i in src.size():
		out[i * 2 + 1] = 255 - src[i] if src[i] < 255 else 0
	return Image.create_from_data(fog.width, fog.height, false, Image.FORMAT_LA8, out)


func _panel_text() -> String:
	var sel := input.selection.selected
	if sel.is_empty():
		return ""
	if sel.size() == 1:
		var o = sel[0]
		if not is_instance_valid(o):
			return ""
		var line := "%s  %d / %d" % [game.name_of(o.get(&"kind")), maxi(roundi(float(o.get(&"hp"))), 0), roundi(float(o.get(&"max_hp")))]
		var b := o as RtsBuilding
		if b != null:
			if not b.finished:
				line += "\nBudowa: %d%%" % roundi(100.0 * b.progress / b.build_time)
			elif not b.production.queue.is_empty():
				var names: Array[String] = []
				for it in b.production.queue:
					names.append(game.name_of(it.id))
				line += "\nW produkcji: %s (%d%%)%s" % [", ".join(names), roundi(b.production.fraction() * 100.0), "  — brak żywności" if b.production.is_blocked() else ""]
		var u := o as RtsUnit
		if u != null and u.is_worker() and u.gatherer.carrying > 0:
			line += "\nNiesie: %d %s" % [u.gatherer.carrying, game.name_of(u.gatherer.carrying_kind)]
		return line
	var counts := {}
	for o in sel:
		var k: StringName = o.get(&"kind")
		counts[k] = int(counts.get(k, 0)) + 1
	var parts: Array[String] = []
	for k in counts:
		parts.append("%s ×%d" % [game.name_of(k), counts[k]])
	return "Zaznaczone: %d\n%s" % [sel.size(), ", ".join(parts)]


func _draw_world() -> void:
	var sel := input.selection.selected
	for o in input.candidates():
		var n := o as Node3D
		var p := input.to_screen(n)
		if p == Vector2.INF:
			continue
		var hp := float(o.get(&"hp"))
		var mx := float(o.get(&"max_hp"))
		var chosen := sel.has(o)
		var team := int(o.get(&"team"))
		if chosen:
			var r := 18.0 if o is RtsUnit else 34.0
			_canvas.draw_set_transform(p + Vector2(0, 14), 0.0, Vector2(1.0, 0.5))
			_canvas.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(0.3, 1.0, 0.4) if team == 0 else Color(1.0, 0.35, 0.3), 2.0)
			_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if chosen or hp < mx:
			var w := BAR_W if o is RtsUnit else BAR_W * 2.0
			var at := p + Vector2(-w * 0.5, -34)
			_canvas.draw_rect(Rect2(at, Vector2(w, 5)), Color(0, 0, 0, 0.7))
			var f := clampf(hp / mx, 0.0, 1.0)
			_canvas.draw_rect(Rect2(at, Vector2(w * f, 5)), Color(0.2, 0.9, 0.3) if f > 0.5 else (Color(0.95, 0.8, 0.2) if f > 0.25 else Color(0.95, 0.25, 0.2)))
	var box := input.drag_rect()
	if box.size != Vector2.ZERO:
		_canvas.draw_rect(box, Color(0.3, 1.0, 0.4, 0.12))
		_canvas.draw_rect(box, Color(0.3, 1.0, 0.4, 0.9), false, 1.5)
	_draw_minimap()


func _draw_minimap() -> void:
	var size := 170.0
	var vp := _canvas.size
	minimap_rect = Rect2(Vector2(12, vp.y - size - 12), Vector2(size, size))
	_canvas.draw_rect(minimap_rect.grow(2), Color(0, 0, 0, 0.8))
	_canvas.draw_rect(minimap_rect, Color(0.3, 0.42, 0.25))
	var to_map := func(p: Vector3) -> Vector2:
		return minimap_rect.position + Vector2((p.x + 36.0) / 72.0, (p.z + 36.0) / 72.0) * size
	for m in game.mines:
		if m.alive and game.fog(0).is_explored(m.global_position):
			_canvas.draw_rect(Rect2(to_map.call(m.global_position) - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1, 0.85, 0.2) if m.kind == &"gold" else Color(0.15, 0.4, 0.15))
	for b in game.buildings:
		if b.visible:
			_canvas.draw_rect(Rect2(to_map.call(b.global_position) - Vector2(3, 3), Vector2(6, 6)), RtsLook.team_colour(b.team))
	for u in game.units:
		if u.visible:
			_canvas.draw_rect(Rect2(to_map.call(u.global_position) - Vector2(1, 1), Vector2(2.5, 2.5)), RtsLook.team_colour(u.team).lightened(0.3))
	_canvas.draw_texture_rect(_fog_tex, minimap_rect, false)
	var c: Vector2 = to_map.call(input.rig.global_position)
	_canvas.draw_rect(Rect2(c - Vector2(14, 9), Vector2(28, 18)), Color(1, 1, 1, 0.9), false, 1.0)


## A click on the minimap jumps the camera there (the host routes left clicks here first).
func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and minimap_rect.has_point(mb.position):
		var f := (mb.position - minimap_rect.position) / minimap_rect.size
		input.rig.jump_to(Vector3(f.x * 72.0 - 36.0, 0, f.y * 72.0 - 36.0))
		get_viewport().set_input_as_handled()
	elif game.winner >= 0 and event.is_action_pressed(&"ui_accept"):
		get_tree().reload_current_scene()
