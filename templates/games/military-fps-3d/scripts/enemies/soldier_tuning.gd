class_name SoldierTuning
extends Resource
## One enemy soldier type's numbers (data/soldier.tres). Difficulty lives in the accuracy (recipe 57 and the genre
## doc): lower accuracy on easy, never shorter warnings. Distances metres, times seconds.

@export_group("Body")
@export var max_health := 100.0              ## the player's rifle: 3 body hits up close, 2 to the head
@export var move_speed := 5.2                ## m/s — they run between covers
@export var color := Color(0.36, 0.34, 0.3)  ## uniform; the red visor and armband stay (readability: hue + value + shape)

@export_group("Gun")
@export var rpm := 450.0
@export var burst_min := 3                   ## rounds per burst
@export var burst_max := 5
@export var burst_pause := 0.35              ## s between bursts
@export var damage := 8.0                    ## per hit on the player (100 health, regenerating)
@export var magazine := 20
@export var reload_time := 2.2
@export var sight_range := 45.0

@export_group("Behaviour (ShooterBrain, recipe 57)")
@export var peek_wait := 1.2                 ## s hidden between peeks
@export var peek_time := 1.6                 ## s exposed per peek
@export var aim_time := 1.5                  ## s of exposure until full accuracy
@export var accuracy_min := 0.15             ## chance a shot hits when a peek starts
@export var accuracy_max := 0.35             ## at full aim, × the mission's difficulty
@export var flank_after := 7.0               ## s of the player not moving before this soldier flanks
@export var near := 8.0                      ## CoverFinder distance band to the player
@export var far := 28.0
