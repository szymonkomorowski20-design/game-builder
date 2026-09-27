class_name StatusDef
extends Resource
## A status effect's rules: how long it lasts, whether it deals damage over time, what it does to stats, and what
## happens when it's applied again (REFRESH: same strength, time restarts; STACK: +1 stack up to max_stacks, time
## restarts, damage and modifiers scale with stacks).

enum Stacking { REFRESH, STACK }

@export var id: StringName = &""
@export var duration := 2.0
@export var tick_interval := 0.5      ## 0 = no damage over time
@export var damage_per_tick := 0      ## per stack
@export var stacking: Stacking = Stacking.REFRESH
@export var max_stacks := 1
@export var modifiers: Array[StatModifier] = []   ## applied while active (source "status:<id>"), FLAT/INCREASED × stacks
