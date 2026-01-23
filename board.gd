extends Node2D
@onready var block_size: float = (load("res://block.tscn").instantiate() as Block).collider.shape.get_rect().size.y
@export var spawn_area: Area2D


func _ready():
	Global.collapse_requested.connect(_on_collapse_requested)
	Global.swap_requested.connect(_on_swap_requested)
	for q in 4:
		print(q)
		for i in 3:
			var offset := Vector2i(Vector2(0,1.9).rotated((q*2+i)*TAU/8))
			print(offset)
	for i in INF:
		await get_tree().create_timer(5).timeout
		prints(i*5)


func _on_collapse_requested(block: Block):
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(block) and block.state == Block.State.IDLE:
		block.state = Block.State.FALLING
		block.set_physics_process(true)
		block.get_neighbor(Vector2.UP, _on_collapse_requested)


func _on_swap_requested(block1: Block, direction: Vector2i):
	var block2 := block1.get_neighbor(direction)
	if not block2: return block1.draggable.reset_position()
	block1.add_collision_exception_with(block2)
	#test whether the move actually starts immediately changing the position
	block1.move( block2.position )
	await block2.move(block1.position)
	for i in 6: await get_tree().physics_frame
	var match1 := Matcher.match_block_drag(block1)
	var match2 := Matcher.match_block_drag(block2)
	if not match1 and not match2:
		block1.move(block2.position)
		await block2.move(block1.position)
	block1.remove_collision_exception_with(block2)
	for i in 6: await get_tree().physics_frame
	if not match1:
		block1.state = Block.State.FALLING
		block1.set_physics_process(true)
	if not match2:
		block2.state = Block.State.FALLING
		block2.set_physics_process(true)
