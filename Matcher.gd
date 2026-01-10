extends Node
var matches: Array[Block]
var block: Block
var directions := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
var shapes: Array[Dictionary] = [
	# for now there's no need to make a shape it's own class, don't overoptimize
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
		handler = func(__): match_line(Vector2.RIGHT)
	}, {
		type = Powerup.Type.ROCKETH, 
		directions = 1, 
		requirement = 4, 
		handler = func(__): match_line(Vector2.UP)
	},{
		type = Powerup.Type.FAN, 
		directions = 4, 
		requirement = 4, 
		handler = func(offset: Vector2):
			# it's more maintainable when there's no loop or complicated math
			match_single(offset)
			match_single(offset.orthogonal())
			match_single(offset + offset.orthogonal())
			if matches.size()<3: return
			# optional matches
			match_single(offset*2)
			match_single(offset.orthogonal()*2)
			match_single(-offset)
			match_single(-offset.orthogonal()),
	}, {
		type = Powerup.Type.NONE, 
		directions = 2,
		requirement = 3, 
		handler = match_line
	}
]


func match_block(_block: Block) -> bool:
	block = _block
	#prints('matching', block)
	for shape: Dictionary in shapes:
		for i in shape.directions:
			matches.clear()
			shape.handler.call(directions[i])
			if matches.size() + 1 < shape.requirement: continue
			if shape.type == Powerup.Type.NONE:
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
	if match_single(offset):
		match_toward(offset+offset.sign())


func match_single(offset: Vector2) -> bool:
	var block2 := Global.get_block(block.position + block.size * offset)
	if not block2: return false
	if block2.powerup: return false
	if not block.type == block2.type: return false
	matches.append(block2)
	return true
