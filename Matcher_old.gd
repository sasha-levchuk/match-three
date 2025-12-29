#class_name Matcher_old
#enum Shape{ DISCOBALL, TNT, ROCKETV, ROCKETH, FAN, THREE }
#static var grid: Node2D
#static var handlers: Dictionary[Shape, Callable] = {
	#Shape.DISCOBALL: match_discoball,
	#Shape.TNT: match_tnt,
	#Shape.ROCKETV: match_line.bind(Vector2(0,1), 3),
	#Shape.ROCKETH: match_line.bind(Vector2(1,0), 3),
	#Shape.FAN: match_fan,
	#Shape.THREE: match_three
#}
#
#
#static func process_coord(coord: Vector2, shape: Shape) -> PackedVector2Array:
	#return handlers[shape].call(coord, grid.tiles[coord].type) as PackedVector2Array
#
#
#static func match_line( coord, facing, minimum:=1, type:Block.Type=grid.tiles[coord].type) -> PackedVector2Array:
	#var matches := match_toward( coord, type, facing )
	#matches.append_array( match_toward( coord, type, facing*-1 ) )
	#if matches.size() >= minimum:
		#return matches
	#return PackedVector2Array()
#
#
#static func match_toward(coord, type, offset, minimum := 1) -> PackedVector2Array:
	#var matches: PackedVector2Array
	#coord += offset
	#while match_coord(coord, type):
		#minimum -= 1
		#matches.append(coord)
		#coord += offset
	#return matches if minimum < 1 else PackedVector2Array()
#
#
#static func match_coord(array: Array[Block], coord: Vector2, type: Block.Type) -> bool:
	#return ( grid.is_valid(coord) and
		#not grid.tiles[coord].is_locked and
		#not grid.tiles[coord].is_powerup and
		#grid.tiles[coord].type==type )
#
#
#static func match_square(coord: Vector2, direction: Vector2) -> PackedVector2Array:
	#var type: Block.Type = grid.tiles[coord].type
	#var result: PackedVector2Array
	#for i in 3:
		#coord += direction
		#if match_coord(coord, type):
			#result.append(coord)
		#direction = direction.orthogonal()
	#if result.size()<3:
		#result.clear()
	#return result
#
#
#static func simple_fill_check(coord: Vector2, type: Block.Type) -> bool:
	#var hor := match_toward(coord, type, Vector2(-1, 0))
	#if hor.size() >= 2:
		#return true
	#var ver := match_toward(coord, type, Vector2(0, -1))
	#if ver.size() >= 2:
		#return true
	#return hor and ver and match_coord( coord + Vector2(-1, -1), type )
#
#
#static func match_discoball(coord, type:Block.Type=grid.tiles[coord].type) -> PackedVector2Array:
	#for facing:Vector2 in [Vector2(0,-1), Vector2(-1,0)]:
		#var matches := match_toward( coord, type, facing, 2 )
		#if not matches:
			#continue
		#matches.append_array( match_toward( coord, type, facing*-1, 2 ) )
		#if matches.size() < 4:
			#continue
		#matches.append_array( match_toward( coord, type, facing.orthogonal(), 2))
		#matches.append_array( match_toward( coord, type, facing.orthogonal()*-1, 2) )
		#return matches
	#return PackedVector2Array()
#
#
#static func match_tnt(coord: Vector2) -> PackedVector2Array:
	#var facing := Vector2(0,-1)
	#var matches_along := match_line( coord, facing, 2 )
	#var matches_ortho := match_line( coord, facing.orthogonal(), 2 )
	#if matches_along and matches_ortho:
		#return matches_along + matches_ortho
	#return PackedVector2Array()
#
#
#static func match_fan(coord: Vector2) -> PackedVector2Array:
	#var type: Block.Type = grid.tiles[coord].type
	#var facing := Vector2(0,-1)
	#for i in 4:
		#var matches := match_square(coord, facing)
		#if matches:
			#var corner := coord + facing * 2
			#if match_coord(corner, type):
				#matches.append(corner)
			#corner = coord + facing.orthogonal() * 2
			#if match_coord(corner, type):
				#matches.append(corner)
			#return matches
		#facing = facing.orthogonal()
	#return PackedVector2Array()
#
#
#static func match_three(coord: Vector2) -> PackedVector2Array:
	#var facing := Vector2(0,-1)
	#for i in 2:
		#var matches := match_line( coord, facing, 2)
		#if matches:
			#return matches
		#facing = facing.orthogonal()
	#return PackedVector2Array()
