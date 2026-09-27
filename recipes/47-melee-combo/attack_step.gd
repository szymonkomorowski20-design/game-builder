class_name AttackStep
extends Resource
## One swing of a melee combo. Times are in seconds; the host decides what "reach" and "arc" mean in its space.

@export var name := "slash"
@export var windup := 0.08      ## before the blade can hit — committed, no dash-cancel
@export var active := 0.06      ## the only window in which it hits
@export var recovery := 0.20    ## after the swing — the next step or a dash may cut it short
@export var damage := 10
@export var knockback := 4.0    ## pushed distance (host units)
@export var reach := 1.6        ## hitbox length (host units)
@export var lunge := 0.0        ## forward step during active (host units), a Hades-style commitment
