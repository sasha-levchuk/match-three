extends Node2D
var get_idle_block: Callable
signal swap_requested
signal collapse_requested
@onready var red_dot := preload("res://red_dot.tscn")


func get_block(where: Vector2) -> Block:
	add_child(red_dot.instantiate().place(where))
	var params := PhysicsPointQueryParameters2D.new()
	params.position = where
	var result: Array = get_world_2d().direct_space_state.intersect_point(params)
	if result.is_empty(): return null
	var node: Node = result.pop_back().collider
	if not node is Block: return null
	var block := node as Block
	if block.state != Block.State.IDLE: return null
	if block.is_queued_for_deletion(): return null
	if not is_instance_valid(block): return null
	return block


func pause(time: float):
	get_tree().paused = true
	get_tree().create_timer(time).timeout.connect(func():
		get_tree().paused = false)
