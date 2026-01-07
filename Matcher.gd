class_name Matcher extends Node
enum Type{DISCOBALL, TNT, ROCKETV, ROCKETH, FAN, THREE}
static var get_block: Callable
static var block_size: Vector2
static var matches: Array[Block]
static var directions := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
static var shapes: Array[Shape] = [
	Shape.new(Type.DISCOBALL, 2, 5, func(coord: Vector2, type: Block.Type, facing: Vector2):
		match_line(coord, type, facing)
		if matches.size()<4: return
		match_line(coord, type, facing.orthogonal())),
	Shape.new(Type.TNT, 1, 5, func(coord: Vector2, type: Block.Type, facing: Vector2):
		match_line(coord, type, facing )
		if matches.size()<2: return
		match_line(coord, type, facing.orthogonal())),
	Shape.new(Type.ROCKETV, 1, 4, func(coord, type, _facing):
		match_line(coord, type, Vector2.UP)),
	Shape.new(Type.ROCKETH, 1, 4, func(coord, type, _facing):
		match_line(coord, type, Vector2.RIGHT)),
	Shape.new(Type.FAN, 4, 4, func(coord: Vector2, type: Block.Type, facing: Vector2):
		for i in 3:
			match_single(coord + block_size * facing.rotated(i*PI/4), type)
		if matches.size()<3: return
		match_single(coord + facing * 2 * block_size, type)
		match_single(coord - facing * block_size, type)
		match_single(coord + facing.orthogonal() * 2 * block_size, type)
		match_single(coord - facing.orthogonal() * block_size, type)),
	Shape.new(Type.THREE, 2, 3, match_line)
]


static func match_block(block: Block) -> bool:
	for shape:Shape in shapes:
		for i in shape.directions:
			matches.clear()
			shape.handler.call(block.position, block.type, directions[i])
			if matches.size() + 1 >= shape.size:
				if shape.type == Type.THREE:
					matches.append(block)
				else:
					block.make_powerup(shape.type)
					block.state = Block.State.IDLE
				for matched_block: Block in matches:
					matched_block.delete()
				return true
	return false


static func match_line(coord: Vector2, type: Block.Type, facing: Vector2):
	match_toward(coord, type, facing)
	match_toward(coord, type, -facing)


static func match_toward(where: Vector2, type: Block.Type, direction: Vector2):
	where += direction * block_size
	if match_single(where, type):
		match_toward( where, type, direction)


static func match_single(where: Vector2, type: Block.Type) -> bool:
	var block := get_block.call( where ) as Block
	if not block: return false
	if block.is_powerup: return false
	if not block.state == Block.State.IDLE: return false
	if not block.type == type: return false
	matches.append( block )
	return true
	return false
