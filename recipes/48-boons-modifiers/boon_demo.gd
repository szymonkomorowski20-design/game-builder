class_name BoonDemo
extends Control
## Three boon cards after a "room". move_left / move_right choose, action takes the card. Taking applies the boon to
## the StatSheet at the offered rarity and deals a new offer (next seed) without anything already owned.

const RARITY_COLOR := {
	Boon.Rarity.COMMON: Color(0.85, 0.85, 0.85),
	Boon.Rarity.RARE: Color(0.4, 0.7, 1.0),
	Boon.Rarity.EPIC: Color(0.8, 0.5, 1.0),
	Boon.Rarity.LEGENDARY: Color(1.0, 0.75, 0.3),
}

var sheet := StatSheet.new({&"speed": 5.0, &"damage": 10.0, &"max_health": 50.0})
var pool := BoonPool.new()
var owned: Array[StringName] = []
var offer: Array[BoonOffer] = []
var selected := 0
var seed := 42

@onready var _cards := $Cards as HBoxContainer
@onready var _stats := $Stats as Label


func _ready() -> void:
	pool.boons = [
		_boon(&"swift_feet", "Swift Feet", "+25% move speed", [&"speed"], &"speed", StatModifier.Op.INCREASED, 0.25),
		_boon(&"heavy_blows", "Heavy Blows", "+30% damage", [&"power"], &"damage", StatModifier.Op.INCREASED, 0.30),
		_boon(&"thick_hide", "Thick Hide", "+20 max health", [&"guard"], &"max_health", StatModifier.Op.FLAT, 20.0),
		_boon(&"keen_edge", "Keen Edge", "+3 damage", [&"power"], &"damage", StatModifier.Op.FLAT, 3.0),
		_boon(&"momentum", "Momentum", "damage ×1.2 (speed + power)", [&"speed", &"power"], &"damage", StatModifier.Op.MORE, 1.2, [&"speed", &"power"]),
	]
	_deal()


func _unhandled_input(event: InputEvent) -> void:
	if offer.is_empty():
		return
	if event.is_action_pressed(&"move_left"):
		selected = wrapi(selected - 1, 0, offer.size())
	elif event.is_action_pressed(&"move_right"):
		selected = wrapi(selected + 1, 0, offer.size())
	elif event.is_action_pressed(&"action"):
		take(selected)
		return
	else:
		return
	_draw_cards()


func take(index: int) -> void:
	var o := offer[index]
	o.boon.apply(sheet, o.rarity)
	owned.append(o.boon.id)
	seed += 1
	_deal()


func _deal() -> void:
	offer = pool.offer(seed, owned, 3)
	selected = 0
	_draw_cards()


func _draw_cards() -> void:
	for c in _cards.get_children():
		c.queue_free()
	for i in offer.size():
		var o := offer[i]
		var card := Label.new()
		card.custom_minimum_size = Vector2(180, 110)
		card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.autowrap_mode = TextServer.AUTOWRAP_WORD
		card.text = "%s%s\n%s\n[%s]" % ["> " if i == selected else "", o.boon.title, o.boon.description, Boon.Rarity.keys()[o.rarity]]
		card.add_theme_color_override(&"font_color", RARITY_COLOR[o.rarity] if i == selected else RARITY_COLOR[o.rarity].darkened(0.4))
		_cards.add_child(card)
	_stats.text = "speed %.2f   damage %.1f   max health %.0f   owned: %s" % [
		sheet.value(&"speed"), sheet.value(&"damage"), sheet.value(&"max_health"), ", ".join(owned)]


static func _boon(id: StringName, title: String, text: String, tags: Array[StringName], stat: StringName, op: StatModifier.Op, value: float, requires: Array[StringName] = []) -> Boon:
	var m := StatModifier.new()
	m.stat = stat
	m.op = op
	m.value = value
	var b := Boon.new()
	b.id = id
	b.title = title
	b.description = text
	b.tags = tags
	b.requires_tags = requires
	b.modifiers = [m]
	return b
