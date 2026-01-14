extends Node
var matches: Array[Block]
var directions := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
var center: Vector2
var cluster: Dictionary[Vector2, Block]
var shapes: Array[Dictionary] = [
	# for now there's no need to make a shape it's own class, don't overoptimize
	{
		type = Powerup.Type.DISCOBALL,
		n_directions = 2, 
		requirement = 5, 
		handler = func(offset: Vector2):
			match_line(offset)
			if matches.size()>=4:
				match_line(offset.orthogonal()),
	}, {
		type = Powerup.Type.TNT, 
		n_directions = 1, 
		requirement = 5,
		handler = func(offset: Vector2):
			match_line(offset )
			if matches.size()<2: return
			match_line(offset.orthogonal()),
	}, {
		type = Powerup.Type.ROCKETV, 
		n_directions = 1, 
		requirement = 4, 
		handler = func(__): match_line(Vector2.RIGHT)
	}, {
		type = Powerup.Type.ROCKETH, 
		n_directions = 1, 
		requirement = 4, 
		handler = func(__): match_line(Vector2.UP)
	},{
		type = Powerup.Type.FAN, 
		n_directions = 4, 
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
		n_directions = 2,
		requirement = 3, 
		handler = match_line
	}
]


func match_block(block: Block) -> bool:
	cluster.clear()
	cluster[Vector2.ZERO] = block
	var unexplored: Array[Vector2] = [Vector2.ZERO]
	while unexplored:
		center = unexplored.pop_back() as Vector2
		for offset: Vector2 in directions:
			var new_coord := center + offset
			if cluster.has(new_coord): continue
			var pos := block.position+center*block.size
			var neighbour := Global.get_block_ray(pos, offset)
			if not neighbour or neighbour.powerup: continue
			if neighbour.type != block.type: continue
			if neighbour.state == Block.State.IDLE:
				prints('found neighbour', neighbour, 'at', new_coord)
				cluster[new_coord] = neighbour
				unexplored.append(new_coord)
			if neighbour.state == Block.State.FALLING and offset==Vector2.UP:
				prints('the cluster is unfinished, halting')
				return false
	prints('cluster', cluster)
	for shape: Dictionary in shapes:
		for i in shape.n_directions:
			var direction := directions[i] as Vector2
			for coord: Vector2 in cluster:
				matches.clear()
				center = coord
				shape.handler.call(direction)
				if matches.size() + 1 < shape.requirement: continue
				if shape.type == Powerup.Type.NONE:
					matches.append(block)
				else:
					block.make_powerup(shape.type as Powerup.Type)
					block.state = Block.State.IDLE
				for matched_block: Block in matches:
					matched_block.delete()
				print('match found', shape)
				return true
	return false


func match_line(offset: Vector2):
	match_toward(offset)
	match_toward(-offset)


func match_toward(offset: Vector2):
	if match_single(offset):
		match_toward(offset+offset.sign())


func match_single(offset: Vector2) -> bool:
	if cluster.has(center+offset):
		matches.append( cluster[center+offset] )
		return true
	return false


#func match_single_old(offset: Vector2) -> bool:
	#var block2 := Global.get_block(block.position + block.size * offset)
	#if not block2: return false
	#if block2.powerup: return false
	#if not block.type == block2.type: return false
	#matches.append(block2)
	#return true
