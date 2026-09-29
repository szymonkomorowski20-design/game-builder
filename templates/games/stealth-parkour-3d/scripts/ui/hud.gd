extends CanvasLayer
## The district's HUD (template stealth-parkour-3d): the contract's phase and goal, health, the notoriety level, the
## chase (seen / searched for, with the circle's distance / escaped), and short messages. The guards show their own
## awareness over their heads (a meter, "?" and "!").

@export var game_path: NodePath = ^".."

var _message_until := 0.0

@onready var game: StealthGame = get_node(game_path)
@onready var goal_label: Label = $Goal
@onready var status_label: Label = $Status
@onready var message_label: Label = $Message


func _ready() -> void:
	game.message.connect(_show)


func _process(_delta: float) -> void:
	goal_label.text = _goal_text()
	var level := game.notoriety.level()
	var pips := "●".repeat(level) + "○".repeat(3 - level)
	status_label.text = "Zdrowie: %d/%d    Rozgłos: %s    %s" % [game.player.health, game.player.max_health, pips,
			_chase_text()]
	if game.clock > _message_until:
		message_label.text = ""


func _show(text: String) -> void:
	message_label.text = text
	_message_until = game.clock + 4.0


func _goal_text() -> String:
	match game.contract.phase:
		Contract.Phase.APPROACH:
			return "Kontrakt: zabij kupca w złotej szacie (klawisz F z bliska, niezauważony)"
		Contract.Phase.ESCAPE:
			return "Uciekaj: zgub pościg i oddal się od ciała"
		Contract.Phase.DONE:
			return "Kontrakt wykonany"
		Contract.Phase.FAILED:
			return "Kontrakt nieudany: " + game.contract.fail_reason
	return ""


func _chase_text() -> String:
	match game.wanted.state:
		WantedSearch.State.SEEN:
			return "Ścigają cię!"
		WantedSearch.State.LOST:
			var d := Vector2(game.player.global_position.x - game.wanted.centre.x,
					game.player.global_position.z - game.wanted.centre.z).length()
			return "Szukają cię (%d m od kręgu)" % maxi(0, int(game.wanted.radius - d))
		WantedSearch.State.ESCAPED:
			return "Zgubiłeś pościg"
	if game.player.is_hidden():
		return "Ukryty"
	if game.player.blended:
		return "W tłumie"
	return ""
