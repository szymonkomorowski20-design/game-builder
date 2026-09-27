class_name NetWorldDemo
extends Node2D
## A server and a client in one window: left half = the server's world, right half = the client's copy. Each half
## is its own multiplayer root (as in the tests). The keyboard steers the CLIENT's avatar — watch the move go to the
## server and come back. A real game runs one NetWorld per process.

var server_world: NetWorld
var client_world: NetWorld


func _ready() -> void:
	server_world = _half("Server", 0.0)
	client_world = _half("Client", 320.0)
	for i in 5:   # a random high port; retry if it is taken
		var port := 24000 + randi() % 4000
		if server_world.host(port) == OK:
			client_world.join("127.0.0.1", port)
			return
	push_error("R46 demo: no free port")


func _half(root_name: String, x: float) -> NetWorld:
	var root := Node2D.new()
	root.name = root_name
	root.position.x = x
	add_child(root)
	get_tree().set_multiplayer(SceneMultiplayer.new(), root.get_path())
	var w := NetWorld.new()
	w.name = "World"
	root.add_child(w)
	var label := Label.new()
	label.text = root_name.to_upper() + " VIEW"
	label.position = Vector2(12, 4)
	root.add_child(label)
	return w


func _physics_process(_delta: float) -> void:
	if client_world != null:
		client_world.local_input(Input.get_vector("move_left", "move_right", "move_up", "move_down"))


func _draw() -> void:
	draw_line(Vector2(320, 0), Vector2(320, 360), Color(1, 1, 1, 0.4), 2.0)


## The worlds close their own sockets (NetWorld._exit_tree); here only the per-branch multiplayer is unregistered —
## the children are already out of the tree when this runs, so their paths come from our own.
func _exit_tree() -> void:
	for root_name in ["Server", "Client"]:
		get_tree().set_multiplayer(null, NodePath(str(get_path()) + "/" + root_name))
