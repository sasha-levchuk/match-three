extends CanvasItem
enum Type{DISCOBALL, TNT, ROCKETV, ROCKETH, FAN, THREE}
var matches: Array[Block]
var block: Block
var directions := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
var shapes: Array[Dictionary] = [
	{
		type = Powerup.Type.DISCOBALL,
		directions = 2, 
		requirement = 5, 
		handler = func(offset: Vector2):
			match_line(offset)
			if matches.size()>=4:
				match_line(offset.orthogonal()),
	}, {
		type = Powerup.Type.TNT, 
		directions = 1, 
		requirement = 5,
		handler = func(offset: Vector2):
			match_line(offset )
			if matches.size()<2: return
			match_line(offset.orthogonal()),
	}, {
		type = Powerup.Type.ROCKETV, 
		directions = 1, 
		requirement = 4, 
		handler = func(__): match_line(Vector2.UP)
	}, {
		type = Powerup.Type.ROCKETH, 
		directions = 1, 
		requirement = 4, 
		handler = func(__): match_line(Vector2.RIGHT)
	},{
		type = Type.FAN, 
		directions = 4, 
		requirement = 4, 
		handler = func(offset: Vector2):
			for i in 3:
				match_single(offset.rotated(i*PI/4))
			if matches.size()<3: return
			match_single(offset*2)
			match_single(offset.orthogonal()*2)
			match_single(-offset)
			match_single(-offset.orthogonal()),
	}, {
		type = Type.THREE, 
		directions = 2,
		requirement = 3, 
		handler = match_line
	}
]


func match_block(_block: Block) -> bool:
	block = _block
	for shape: Dictionary in shapes:
		for i in shape.directions:
			matches.clear()
			shape.handler.call(directions[i])
			if matches.size() + 1 >= shape.size:
				if shape.type == Type.THREE:
					matches.append(block)
				else:
					block.make_powerup(shape.type as Powerup.Type)
					block.state = Block.State.IDLE
				for matched_block: Block in matches:
					matched_block.delete()
				return true
	return false


func match_line(offset: Vector2):
	match_toward(offset)
	match_toward(-offset)


func match_toward(offset: Vector2):
	while match_single(offset):
		match_toward(offset+offset.sign())


func match_single(offset: Vector2) -> bool:
	var matched_block := get_idle_block(offset)
	if not matched_block or not block.type == matched_block.type: return false
	matches.append(match_block)
	return true


func get_idle_block(where: Vector2) -> Block:
	var block := get_block(where)
	if block.state==Block.State.IDLE: return null
	if block.powerup: return null
	return block


func get_block(offset: Vector2) -> Block:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = block.position + offset * block.size
	var result: Array = get_world_2d().direct_space_state.intersect_point(params)
	if result.is_empty(): return null
	var node: Node = result.pop_back().collider
	return node as Block if node is Block else null
