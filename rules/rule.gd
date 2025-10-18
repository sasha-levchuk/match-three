class_name Rule
extends Resource

@export var name: String
@export var min_size: int
@export var reward: Powerup.Type
@export var directions: Array[Vector2i]
var matchers_main: Dictionary[Powerup.Type,Callable] = {
	Powerup.Type.DISCOBALL: match_line,
	Powerup.Type.TNT: func(coord, _direction, type):
		match_line(coord, Vector2i.DOWN, type)
		var size := matches.size()
		if size >= 2:
			match_line(coord, Vector2i.LEFT, type)
			if matches.size() - size < 2:
				matches.clear(),
	Powerup.Type.ROCKET: match_line,
	Powerup.Type.FAN: func(coord, direction, type):
		for i in 3:
			coord += direction
			if not match_single(coord, type):
				break
			direction = ortho(direction),
	Powerup.Type.NONE: match_line,
}
var matchers_optional: Dictionary[Powerup.Type,Callable] = {
	Powerup.Type.DISCOBALL: func(coord, direction, type):
		match_direction(coord, ortho(direction), type)
		match_direction(coord, ortho(-direction), type),
	Powerup.Type.TNT: Callable(),
	Powerup.Type.ROCKET: Callable(),
	Powerup.Type.FAN: func(coord, direction, type):
		match_single(coord+direction*2, type)
		match_single(coord+ortho(direction)*2, type)
		match_single(coord-direction, type)
		match_single(coord-ortho(direction), type),
	Powerup.Type.NONE: Callable(),
}
var matcher_main: Callable
var matcher_optional: Callable
var piece_getter: Callable
var matches: Array[Piece]


func setup( grid: Node ):
	piece_getter = grid.get_piece
	matcher_main = matchers_main[reward]
	matcher_optional = matchers_optional[reward]


func execute(coord: Vector2i, type: Matchable.Type):
	for direction in directions:
		matches.clear()
		matcher_main.call(coord, direction, type)
		if matches.size() >= min_size-1:
			if matcher_optional.is_valid():
				matcher_optional.call(coord, direction, type)
			return true


func match_line(coord, direction, type):
	match_direction(coord, direction, type)
	match_direction(coord, -direction, type)


func match_direction(coord, direction, type):
	while match_single(coord + direction, type):
		coord += direction


func match_single(coord, type):
	var piece := piece_getter.call(coord) as Piece
	if piece and piece.matchable and piece.matchable.type==type and piece.state==Piece.State.IDLE:
		matches.append(piece)
		return true
	return false


func ortho(v) -> Vector2i:
	return Vector2i(Vector2(v).orthogonal()) # Vector2i(v.y, v.x)
