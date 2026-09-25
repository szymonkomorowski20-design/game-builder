extends GutTest
## R20 — released nodes are reused (no new instances), parked nodes are hidden and disabled,
## the cap is respected, double release does not duplicate.


func _pool(max_size: int = 4) -> NodePool:
	var p := NodePool.new()
	p.scene = load("res://20-object-pool/spark.tscn")
	p.max_size = max_size
	add_child_autofree(p)
	return p


func test_r20_reuse_instead_of_instantiate() -> void:
	var p := _pool()
	var a := p.acquire()
	p.release(a)
	var b := p.acquire()
	assert_same(a, b)
	assert_eq(p.created, 1)


func test_r20_parked_nodes_hidden_and_disabled() -> void:
	var p := _pool()
	p.prewarm(3)
	assert_eq(p.available(), 3)
	for n in p.get_children():
		assert_false((n as Node2D).visible)
		assert_eq(n.process_mode, Node.PROCESS_MODE_DISABLED)
	var got := p.acquire() as Node2D
	assert_true(got.visible)
	assert_eq(got.process_mode, Node.PROCESS_MODE_INHERIT)


func test_r20_cap_respected() -> void:
	var p := _pool(2)
	assert_not_null(p.acquire())
	assert_not_null(p.acquire())
	assert_null(p.acquire(), "beyond max_size → null, not a new node")
	assert_eq(p.created, 2)


func test_r20_double_release_is_ignored() -> void:
	var p := _pool()
	var a := p.acquire()
	p.release(a)
	p.release(a)
	assert_eq(p.available(), 1)
	assert_ne(p.acquire(), p.acquire(), "two acquires never return the same node")
