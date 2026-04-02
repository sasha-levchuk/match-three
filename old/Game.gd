extends Node2D
const GRID_SIZE := Vector2(108,108)
var score := 0
signal tnt_exploded
signal score_incremented
signal match_queried


func _ready():
	score_incremented.connect(func():score += 1)
	match_queried.connect(make_marker)
	

func make_marker(pos:Vector2):
	var marker: Sprite2D = load('res://match_marker.tscn').instantiate()
	prints('match queried at', pos, marker)
	add_sibling(marker)
	marker.position = pos
	var tween := create_tween()
	tween.tween_property(marker,'modulate:a', 0.0, 1.0)
	tween.tween_callback(marker.queue_free)


func make_powerup(type: Powerup.Type, pos: Vector2) -> Block:
	var block := load("res://block.tscn").instantiate() as Block
	block.powerup = Powerup.new(block, type)
	block.position = pos
	get_tree().create_timer(0.05).timeout.connect(add_sibling.bind(block))
	return block


func animate_projectile(thing: Node2D):
	var trajectory: Path2D = load("res://trajectory.tscn").instantiate()
	add_sibling(trajectory)
	return trajectory.animate_projectile(thing)


func get_block(pos: Vector2)->Block:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = pos*GRID_SIZE + GRID_SIZE/2
	var result := get_world_2d().direct_space_state.intersect_point(params)
	if result.is_empty(): return null
	make_marker(params.position)
	var node: Node = result.pop_back().collider
	if not node is Block: return null
	var block := node as Block
	var idle_only := true
	if idle_only and not block.state == Block.State.IDLE: return null
	return block


func call_block(posi: Vector2i, callback: Callable):
	var block := get_block(posi)
	return callback.call(block) if block else null


func gather_blocks_toward(pos: Vector2i, offset: Vector2i, type: Matchable.Type) -> Array[Block]:
	var blocks := [] as Array[Block]
	for i in 10:
		var block := get_block(pos+offset*i)
		if block and block.matchable and block.matchable.type == type:
			blocks.append(block)
		else: 
			break
	return blocks
