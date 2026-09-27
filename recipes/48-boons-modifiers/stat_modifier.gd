class_name StatModifier
extends Resource
## One change to one stat. FLAT adds to the base; INCREASED percentages add up with each other (+20% and +30% =
## +50%); MORE multiplies (×1.5 then ×1.2 = ×1.8). `source` groups modifiers so a boon/item can be removed whole.

enum Op { FLAT, INCREASED, MORE }

@export var stat: StringName = &"damage"
@export var op: Op = Op.INCREASED
@export var value := 0.1
@export var source: StringName = &""
