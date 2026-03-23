extends Node
enum Shape {DISCOBALL, TNT, ROCKETH, ROCKETV, FAN, THREE}

class MatchResult:
	var is_successful := false
	var n_matches := 0

func match_blocks_on_drag(...blocks: Array) -> MatchResult:
	var result := MatchResult.new()
	for block: Block in blocks:
		var cluster := gather_neighbors(block, Vector2i.ZERO)
		for shape: Shape in Shape.values():
			if cluster.match_shape(shape):
				result.is_successful = true
				result.n_matches += 1
			else:
				block.fall()
	return result


class Cluster:
	var cells := {} as Dictionary[Vector2i, Block]
	var has_falling_neighbours := false
	
	var shape_handlers: Dictionary[Shape, Callable] = {
		Shape.DISCOBALL: func(coord: Vector2):
			for offset: Vector2i in [Vector2i.DOWN, Vector2i.RIGHT]:
				var matches := [] as Array[Block]
				if match_toward(coord, offset) >= 2 and match_toward(coord, -offset) >= 2:
					match_line(coord, Vector2i(Vector2(offset).orthogonal()))
					return matches
			return false,
		Shape.TNT: func(coord: Vector2i) -> bool:
			return match_line(coord,Vector2i.UP)>=2 and match_line(coord,Vector2i.RIGHT)>=2,
		Shape.ROCKETH: func(coord: Vector2i) -> bool:
			return match_line(coord,Vector2i.UP)>=3,
		Shape.ROCKETV: func(coord: Vector2i) -> bool:
			return match_line(coord,Vector2i.RIGHT)>=3,
		Shape.FAN: func(coord: Vector2i) -> bool:
			var match_quadrant := func(quadrant: int):
				for a: Array in [[1,0],[1,1],[0,1]]:
					var offset := Vector2i(Vector2(a[0],a[1]).rotated(quadrant*TAU/4).round())
					var block: Block = cells.get(coord + offset)
					if not block: return false
					matches.append(block)
				for a: Array in [[2,0],[0,2],[-1,0],[0,-1]]:
					var offset := Vector2i(Vector2(a[0],a[1]).rotated(quadrant*TAU/4).round())
					if cells.has(coord + offset):
						matches.append(cluster[coord + offset])
				return true
			for quadrant: int in 4:
				matches.clear()
				if match_quadrant.call(quadrant):
					return true
			return false,
		Shape.THREE: func(coord: Vector2i) -> bool:
			for v in [Vector2i.RIGHT, Vector2i.DOWN]:
				matches.clear()
				if match_line(coord, v)>=2:
					return true
			return false
	}
	
	func match_shape(shape: Shape) -> MatchResult:
		return match_shape_at_coord(shape, Vector2i.ZERO)
	
	func match_shape_at_coord(shape: Shape, coord:=Vector2i.ZERO) -> MatchResult:
		if shape_handlers[shape].call(coord): 
			cluster[coord].make_powerup(type)
			for block: Block in matches: block.delete()
			return true
		return false
	
	func match_line(center: Vector2i, offset: Vector2i) -> int:
		return match_toward(center, offset, match_toward(center, -offset))

	func match_toward(center: Vector2i, offset: Vector2i, i:=0) -> int:
		while cells.has(center+offset):
			matches.append(cluster[center+offset])
			offset += offset.sign()
			i += 1
		return i


func match_block_fall(block: Block):
	var cluster := gather_neighbors(block, Vector2i.ZERO)
	if cluster.has_falling_neighbours: return
	for shape: Shape in Shape:
		for coord: Vector2i in cluster.cells:
			if cluster.match_shape_at_coord(shape, coord): return


func gather_neighbors(block: Block, coord: Vector2i, cluster:=Cluster.new()) -> Cluster:
	cluster.cells[coord] = block
	for offset: Vector2i in [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]:
		if cluster.has(coord+offset): continue
		var neighbor := block.get_neighbor(offset)
		if not neighbor or not neighbor.matchable: continue
		if neighbor.matchable.type != block.matchable.type: continue
		if neighbor.state == Block.State.IDLE:
			gather_neighbors(neighbor, coord+offset, cluster)
		elif neighbor.state == Block.State.FALLING:
			cluster.has_falling_neighbours = true
	return cluster
