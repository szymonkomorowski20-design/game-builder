class_name RogueUI
extends Control
## The game's screen layer: health, run status, the boss bar, the boon choice (move_left / move_right, attack or
## action to take), the shrine (move_up / move_down, action to buy, attack or pause to leave) and short banners.
## Built in code so the template has no UI scene to keep in sync; restyle freely.

signal boon_chosen(index: int)
signal upgrade_bought(id: StringName)
signal shrine_closed

enum Mode { NONE, BOONS, SHRINE }

var mode := Mode.NONE
var selected := 0
var _offer: Array[BoonOffer] = []
var _upgrades: Array[StringName] = []
var _meta: MetaProgress
var _banner_left := 0.0

var _hp := ProgressBar.new()
var _hp_text := Label.new()
var _status := Label.new()
var _boss := ProgressBar.new()
var _panel := Label.new()
var _banner := Label.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp.position = Vector2(20, 20)
	_hp.size = Vector2(260, 22)
	_hp.show_percentage = false
	_style_bar(_hp, Color(0.85, 0.2, 0.25))
	add_child(_hp)
	_hp_text.position = Vector2(26, 19)
	add_child(_hp_text)
	_status.position = Vector2(20, 48)
	add_child(_status)
	_boss.position = Vector2(390, 20)
	_boss.size = Vector2(500, 18)
	_boss.show_percentage = false
	_style_bar(_boss, Color(0.6, 0.25, 0.8))
	_boss.visible = false
	add_child(_boss)
	_panel.position = Vector2(240, 200)
	_panel.size = Vector2(800, 300)
	_panel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_theme_font_size_override(&"font_size", 22)
	var panel_bg := StyleBoxFlat.new()
	panel_bg.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	panel_bg.set_content_margin_all(16)
	_panel.add_theme_stylebox_override(&"normal", panel_bg)
	_panel.visible = false
	add_child(_panel)
	_banner.position = Vector2(240, 120)
	_banner.size = Vector2(800, 40)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override(&"font_size", 26)
	add_child(_banner)


func _process(delta: float) -> void:
	_banner_left = maxf(_banner_left - delta, 0.0)
	_banner.visible = _banner_left > 0.0


func set_health(current: int, max_health: int) -> void:
	_hp.max_value = max_health
	_hp.value = current
	_hp_text.text = "HP %d / %d" % [current, max_health]


func set_run(run: RunState, rooms: int, owned: Array[StringName]) -> void:
	_status.text = "Room %d/%d · embers %d · boons: %s" % [run.depth + 1, rooms, run.collected, ", ".join(owned) if not owned.is_empty() else "none"]


func show_hub(meta: MetaProgress) -> void:
	_status.text = "Hub · %d embers banked · shrine: walk up and press E · the door on the right starts a run" % meta.currency
	hide_boss()


func set_boss(current: int, max_health: int) -> void:
	_boss.visible = true
	_boss.max_value = max_health
	_boss.value = current


func hide_boss() -> void:
	_boss.visible = false


static func _style_bar(bar: ProgressBar, fill: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.12, 0.85)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	bar.add_theme_stylebox_override(&"background", bg)
	bar.add_theme_stylebox_override(&"fill", fg)


func banner(text: String, seconds: float = 1.6) -> void:
	_banner.text = text
	_banner_left = seconds


func show_boons(offer: Array[BoonOffer]) -> void:
	_offer = offer
	mode = Mode.BOONS
	selected = 0
	_draw_panel()


func show_shrine(meta: MetaProgress) -> void:
	_meta = meta
	_upgrades.assign(meta.upgrades.keys())
	if mode != Mode.SHRINE:
		selected = 0
	mode = Mode.SHRINE
	_draw_panel()


func _unhandled_input(event: InputEvent) -> void:
	if mode == Mode.NONE:
		return
	var count := _offer.size() if mode == Mode.BOONS else _upgrades.size()
	var prev := &"move_left" if mode == Mode.BOONS else &"move_up"
	var next := &"move_right" if mode == Mode.BOONS else &"move_down"
	if event.is_action_pressed(prev):
		selected = wrapi(selected - 1, 0, count)
	elif event.is_action_pressed(next):
		selected = wrapi(selected + 1, 0, count)
	elif mode == Mode.BOONS and (event.is_action_pressed(&"attack") or event.is_action_pressed(&"action")):
		mode = Mode.NONE
		_panel.visible = false
		boon_chosen.emit(selected)
	elif mode == Mode.SHRINE and event.is_action_pressed(&"action"):
		upgrade_bought.emit(_upgrades[selected])
	elif mode == Mode.SHRINE and (event.is_action_pressed(&"attack") or event.is_action_pressed(&"pause")):
		mode = Mode.NONE
		_panel.visible = false
		shrine_closed.emit()
	else:
		return
	get_viewport().set_input_as_handled()
	if mode != Mode.NONE:
		_draw_panel()


func _draw_panel() -> void:
	_panel.visible = true
	var lines := PackedStringArray()
	if mode == Mode.BOONS:
		lines.append("Choose a boon  (← →, J/E to take)")
		for i in _offer.size():
			var o := _offer[i]
			lines.append("%s%s [%s] — %s" % ["> " if i == selected else "   ", o.boon.title, Boon.Rarity.keys()[o.rarity].capitalize(), o.boon.description])
	else:
		lines.append("Shrine — %d embers  (↑ ↓, E to buy, J/Esc to leave)" % _meta.currency)
		for i in _upgrades.size():
			var id := _upgrades[i]
			var maxed := _meta.level(id) >= int(_meta.upgrades[id].max_level)
			lines.append("%s%s  lv %d  %s" % ["> " if i == selected else "   ", String(id).capitalize(), _meta.level(id), "MAX" if maxed else "cost %d" % _meta.cost(id)])
	_panel.text = "\n".join(lines)
