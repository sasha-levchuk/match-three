extends Node
var block: Block
var matches: Array[Block]
var handlers: Dictionary[Powerup.Type, Callable] = {
	Powerup.Type.DISCOBALL: func(coord: Vector2) -> bool:
		for offset: Vector2i in [Vector2i.DOWN, Vector2i.RIGHT]:
			matches.clear()
			if match_toward(coord, offset) >= 2 and match_toward(coord, -offset) >= 2:
				match_line(coord, Vector2i(Vector2(offset).orthogonal()))
				prints('discoball matched')
				return true
		return false,
	Powerup.Type.TNT: func(coord: Vector2i) -> bool:
		return match_line(coord,Vector2i.UP)>=2 and match_line(coord,Vector2i.RIGHT)>=2,
	Powerup.Type.ROCKETH: func(coord: Vector2i) -> bool:
		return match_line(coord,Vector2i.UP)>=3,
	Powerup.Type.ROCKETV: func(coord: Vector2i) -> bool:
		return match_line(coord,Vector2i.RIGHT)>=3,
	Powerup.Type.FAN: func(coord: Vector2i) -> bool:
		var match_quadrant := func(quadrant: int):
			matches.clear()
			for i: int in 3:
				var offset := Vector2i(Vector2(0,1.9).rotated((quadrant*2+i)*TAU/8))
				var b: Block = cluster.get(coord+offset)
				prints('quadrant', quadrant, 'cell', offset, b)
				if not b: return false
				matches.append(cluster[coord+offset])
			for i in 4: # don't ask
				var offset := Vector2i(Vector2(.5,.5).rotated(quadrant*TAU/4)+\
					Vector2(1.6,0).rotated((quadrant+i)*TAU/4))
				if cluster.has(coord+offset):
					matches.append(cluster[coord+offset])
			return true
		for quadrant: int in 4:
			if match_quadrant.call(quadrant):
				return true
		return false,
	Powerup.Type.NONE: func(coord: Vector2i) -> bool:
		for v in [Vector2i.RIGHT, Vector2i.DOWN]:
			matches.clear()
			if match_line(coord, v)>=2:
				return true
		return false
}


var cluster: Dictionary[Vector2i, Block] = {}
func match_block_drag(_block: Block) -> bool:
	block = _block
	cluster.clear()
	gather_neighbors(block, Vector2i.ZERO, false)
	prints(block, 'cluster', cluster)
	for type: Powerup.Type in handlers:
		if match_in_cluster(type):
			return true
	return false


func match_block_fall(_block: Block):
	block = _block
	prints('')
	prints('cluster has been cleared')
	cluster.clear()
	if not gather_neighbors(block, Vector2i.ZERO, true): return
	for type: Powerup.Type in handlers:
		for coord: Vector2i in cluster:
			if match_in_cluster(type, coord): return


func gather_neighbors(central_block: Block, coord: Vector2i, wait_falling: bool):
	cluster[coord] = central_block
	for offset: Vector2i in [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]:
		if cluster.has(coord+offset): continue
		var neighbor := central_block.get_neighbor(offset)
		if not neighbor or neighbor.powerup or neighbor.type!=block.type: continue
		if neighbor.state == Block.State.IDLE:
			if not gather_neighbors(neighbor, coord+offset, wait_falling):
				return false # propagate the terminating condition upwards
		elif wait_falling and neighbor.state == Block.State.FALLING:
			prints('block', neighbor, 'is falling, cluster is unfinished')
			return false
	return true


func match_in_cluster(type: Powerup.Type, coord := Vector2i.ZERO) -> bool:
	matches.clear()
	if not handlers[type].call(coord): return false
	prints('matched', Powerup.str(type), matches, 'in cluster', cluster)
	cluster[coord].make_powerup(type)
	for b: Block in matches: b.delete()
	return true


func match_line(center: Vector2i, offset: Vector2i) -> int:
	return match_toward(center, offset, match_toward(center, -offset))


func match_toward(center: Vector2i, offset: Vector2i, i:=0) -> int:
	while cluster.has(center+offset):
		matches.append(cluster[center+offset])
		offset += offset.sign()
		i += 1
	return i
