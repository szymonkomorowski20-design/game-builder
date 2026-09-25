class_name ItemDef
extends Resource
## Static description of an item type (one .tres per item). Instances in an inventory reference it by id.

@export var id: StringName
@export var display_name: String
@export var max_stack: int = 99
@export var value: int = 1          ## base price used by the shop recipe (11)
