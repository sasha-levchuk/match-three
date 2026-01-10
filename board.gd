extends Node2D
@onready var block_size: float = (load("res://block.tscn").instantiate() as Block).collider.shape.get_rect().size.y
@export var spawn_area: Area2D


func _ready():
	Global.swap_requested.connect(_on_swap_requested)
	Global.collapse_requested.connect(_on_collapse_requested)
	for i in INF:
		await get_tree().create_timer(1).timeout
		prints(i)


func _on_swap_requested(block1: Block, direction: Vector2):
	var block2 := Global.get_block( block1.position + direction * block_size )
	if not block2: return block1.draggable.reset_position()
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


func _on_collapse_requested(where: Vector2):
	var block := Global.get_block(where)
	if block: 
		if block.state == Block.State.IDLE:
			block.fall()
			await get_tree().create_timer(0.05).timeout
		else:
			return
	if where.y > 0:
		_on_collapse_requested(where + Vector2.UP * block_size)
