extends Node2D
@onready var block_size: Vector2 = load("res://block.tscn").instantiate().collider.shape.size
@export var spawn_area: Area2D


func _ready():
	Matcher.get_block = get_block
	Matcher.block_size = block_size
	Event.swap_requested.connect(_on_swap_requested)
	Event.block_landed.connect(Matcher.match_block)
	Event.block_deleted.connect(collapse_up_recursive)
	Event.collapse_initiated.connect(collapse_up_recursive)


func _on_swap_requested(block1: Block, direction: Vector2):
	var block2 := get_block( block1.position + direction * block_size )
	if ( not block2 or 
		block2.is_queued_for_deletion() or
		not is_instance_valid(block2) or
		not block2.state==Block.State.IDLE
	): 
		return block1.draggable.reset_position()
	block1.add_collision_exception_with(block2)
	block1.move( block2.position )
	await block2.move(block1.position)
	for i in 6: await get_tree().physics_frame
	var match1 := Matcher.match_block(block1)
	var match2 := Matcher.match_block(block2)
	if not match1 and not match2:
		block1.move( block2.position )
		await block2.move( block1.position )
	block1.remove_collision_exception_with(block2)
	for i in 6: await get_tree().physics_frame
	if not match1:
		block1.check_and_fall()
	if not match2:
		block2.check_and_fall()


func _on_button_delete_all_pressed():
	for child in get_children():
		if child is Block:
			child.delete()


func collapse_up_recursive(where: Vector2):
	where.y -= block_size.y
	var block_above := get_block(where)
	if block_above: 
		if block_above.state == Block.State.IDLE:
			block_above.fall()
			await get_tree().create_timer(0.05).timeout
		else:
			return
	if where.y > 0:
		collapse_up_recursive(where)


func get_block(where: Vector2) -> Block:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = where
	var result: Array = get_world_2d().direct_space_state.intersect_point(params)
	if result.is_empty(): return null
	var node: Node = result.pop_back().collider
	return node as Block if node is Block else null
