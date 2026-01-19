extends Node
var block: Block
var matches: Array[Block]
var cluster: Dictionary[Vector2, Block]
var handlers: Dictionary[Powerup.Type, Callable] = {
	Powerup.Type.DISCOBALL: func(coord: Vector2) -> bool:
		for offset: Vector2 in [Vector2.DOWN, Vector2.RIGHT]:
			matches.clear()
			if match_toward(coord, offset) >= 2 and match_toward(coord, -offset) >= 2:
				match_toward(coord, offset.orthogonal())
				match_toward(coord, -offset.orthogonal())
				prints('discoball matched')
				return true
		return false,
	Powerup.Type.TNT: func(coord: Vector2) -> bool:
		return match_line(coord,Vector2.UP)>=2 and match_line(coord,Vector2.RIGHT)>=2,
	Powerup.Type.ROCKETH: func(coord: Vector2) -> bool:
		return match_line(coord,Vector2.UP)>=3,
	Powerup.Type.ROCKETV: func(coord: Vector2) -> bool:
		return match_line(coord,Vector2.RIGHT)>=3,
	Powerup.Type.FAN: func(coord: Vector2) -> bool:
		prints('fan matching at', coord, cluster)
		for i in 4:
			prints('iteration', i)
			matches.clear()
			for offset: Vector2 in [Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]:
				var pos := coord + Vector2( Vector2i( offset.rotated(i*PI*.5) ) )
				prints('offset', offset, 'pos', pos, cluster.get(pos))
				if cluster.has(pos): 
					prints('fan matched at offsset', offset, 'rotated', pos)
					matches.append(cluster[pos])
				if matches.size() >= 3:
					for optional: Vector2 in [Vector2.LEFT, Vector2.UP, Vector2.RIGHT*2, Vector2.DOWN*2]:
						pos = coord + Vector2( Vector2i( optional.rotated(i*PI*.5) ) )
						if cluster.has(pos): matches.append(cluster[pos])
					return true
		return false,
	Powerup.Type.NONE: func(coord: Vector2) -> bool:
		for offset: Vector2 in [Vector2.RIGHT, Vector2.DOWN]:
			if match_line(coord, offset)>=2:
				return true
		return false
}


func gather_cluster(should_wait_falling: bool):
	cluster.clear()
	cluster[Vector2.ZERO] = block
	var unexplored: Array[Vector2] = [Vector2.ZERO]
	while unexplored:
		var center := unexplored.pop_back() as Vector2
		for offset: Vector2 in [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN]:
			var new_coord := center + offset
			if cluster.has(new_coord): continue
			var world_coord := block.position + center * block.size
			var where_to := offset*block.size
			if offset==Vector2.UP: where_to *= 3
			var neighbour := Global.get_block_ray(world_coord, where_to)
			if not neighbour or neighbour.powerup: continue
			if neighbour.type != block.type: continue
			if neighbour.state == Block.State.IDLE:
				prints(block, 'found neighbour', neighbour, 'at', new_coord, 'offset', offset)
				cluster[new_coord] = neighbour
				unexplored.append(new_coord)
			if should_wait_falling and \
			neighbour.state == Block.State.FALLING and \
			offset==Vector2.UP:
				prints('the cluster is unfinished, halting')
				return false
	prints('cluster', cluster)


func match_block_drag(_block: Block) -> bool:
	block = _block
	prints('============')
	prints('dragging', block)
	gather_cluster(false)
	for powerup_type: Powerup.Type in handlers:
		matches.clear()
		if handlers[powerup_type].call(Vector2.ZERO):
			prints('matched powerup type', Powerup.Type.keys()[powerup_type])
			for matched_block: Block in matches:
				matched_block.delete()
			block.make_powerup(powerup_type)
			return true
	return false


func match_block_fall(_block: Block):
	block = _block
	gather_cluster(true)
	for coord: Vector2 in cluster:
		for powerup_type: Powerup.Type in handlers:
			matches.clear()
			if handlers[powerup_type].call(coord):
				cluster[coord].make_powerup(powerup_type)
				for matched_block: Block in matches:
					matched_block.delete()


func match_line(center: Vector2, offset: Vector2) -> int:
	return match_toward(center, offset, match_toward(center, -offset))


func match_toward(center: Vector2, offset: Vector2, i:=0) -> int:
	while cluster.has(center+offset):
		matches.append(cluster[center+offset])
		offset += offset.sign()
		i += 1
	return i
