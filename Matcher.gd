class_name Matcher
enum Shape{ DISCOBALL, TNT, ROCKETV, ROCKETH, FAN, THREE }
static var get_block: Callable
static var block_size: Vector2
static var matches: Array[Block]
static var handlers: Dictionary[Shape, Callable] = {
	Shape.DISCOBALL: match_discoball,
	Shape.TNT: match_tnt,
	Shape.ROCKETV: match_line_ver,
	Shape.ROCKETH: match_line_hor,
	Shape.FAN: match_fan,
	Shape.THREE: match_three
}


static func match_block(block: Block) -> bool:
	for shape:Shape in handlers:
		if handlers[shape].call(block.position, block.type):
			matches.append(block)
			for matched_block: Block in matches:
				matched_block.delete()
			return true
	return false


static func match_discoball(coord: Vector2, type: Block.Type) -> bool:
	for facing:Vector2 in [Vector2(0,-1), Vector2(-1,0)]:
		matches = [] as Array[Block]
		match_toward( coord, type, facing )
		if matches.size() < 2:
			continue
		match_toward( coord, type, -facing)
		if matches.size() < 4:
			continue
		match_toward( coord, type, facing.orthogonal())
		match_toward( coord, type, -facing.orthogonal())
		return true
	return false


static func match_tnt(coord: Vector2, type: Block.Type) -> bool:
	matches = [] as Array[Block]
	match_line( coord, type, Vector2.UP )
	if matches.size() < 2: return false
	match_line( coord, type, Vector2.RIGHT )
	if matches.size() < 4: return false
	return true


static func match_line_ver(coord: Vector2, type: Block.Type) -> bool:
	matches = [] as Array[Block]
	match_line( coord, type, Vector2.UP )
	return matches.size() >= 2


static func match_line_hor(coord: Vector2, type: Block.Type) -> bool:
	matches = [] as Array[Block]
	match_line( coord, type, Vector2.RIGHT )
	return matches.size() >= 2


static func match_fan(coord: Vector2, type: Block.Type) -> bool:
	for facing: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		matches = [] as Array[Block]
		if match_square(coord, type, facing):
			match_single(coord + facing * 2 * block_size, type)
			match_single(coord + facing.orthogonal() * 2 * block_size, type)
			return true
	return false


static func match_square(coord: Vector2, type: Block.Type, direction: Vector2) -> bool:
	for i in 3:
		coord += direction * block_size
		match_single(coord, type)
		direction = direction.orthogonal()
	return matches.size() == 3


static func match_three(coord: Vector2, type: Block.Type) -> bool:
	for facing: Vector2 in [Vector2.UP, Vector2.RIGHT]:
		matches = [] as Array[Block]
		match_line(coord, type, facing)
		if matches.size() >= 2:
			return true
	return false


static func match_line( coord: Vector2, type: Block.Type, facing: Vector2):
	match_toward( coord, type, facing )
	match_toward( coord, type, -facing )


static func match_toward( where: Vector2, type: Block.Type, direction: Vector2):
	where += direction * block_size
	if match_single(where, type):
		match_toward( where, type, direction)


static func match_single( where: Vector2, type: Block.Type) -> bool:
	var block := get_block.call( where ) as Block
	if block and block.type == type and block.state == Block.State.IDLE:
		matches.append( block )
		return true
	return false
