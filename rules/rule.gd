class_name Rule
extends Resource

static var get_piece: Callable
@export var name: String
@export var min_size: int
@export var reward: Powerup.Type
@export var directions: Array[Vector2i]
var matcher_main: Callable
var matcher_optional: Callable
var matches: Array[Piece]


func setup():
	matcher_main = {
		Powerup.Type.DISCOBALL: match_line,
		Powerup.Type.TNT: func(coord, _direction, type):
			match_line(coord, Vector2i.DOWN, type)
			var size := matches.size()
			if size >= 2:
				match_line(coord, Vector2i.LEFT, type)
				if matches.size() - size < 2:
					matches.clear(),
		Powerup.Type.ROCKET_V: match_line,
		Powerup.Type.ROCKET_H: match_line,
		Powerup.Type.FAN: func(coord, direction, type):
			for i in 3:
				coord += direction
				if not match_single(coord, type):
					break
				direction = ortho(direction),
		Powerup.Type.NONE: match_line
		}[reward]
	matcher_optional = {
		Powerup.Type.DISCOBALL: func(coord, direction, type):
			match_direction(coord, ortho(direction), type)
			match_direction(coord, ortho(-direction), type),
		Powerup.Type.TNT: Callable(),
		Powerup.Type.ROCKET_V: Callable(),
		Powerup.Type.ROCKET_H: Callable(),
		Powerup.Type.FAN: func(coord, direction, type):
			match_single(coord+direction*2, type)
			match_single(coord+ortho(direction)*2, type)
			match_single(coord-direction, type)
			match_single(coord-ortho(direction), type),
		Powerup.Type.NONE: Callable(),
		}[reward]


func match_piece(piece: Piece):
	for direction in directions:
		matches.clear()
		matcher_main.call(piece.coord, direction, piece.matchable.type)
		if matches.size() >= min_size-1:
			matches.append(piece)
			if matcher_optional.is_valid():
				matcher_optional.call(piece.coord, direction, piece.matchable.type)
			matches.filter(func(p):p.destroy())
			return true
	return false


func match_line(coord, direction, type):
	match_direction(coord, direction, type)
	match_direction(coord, -direction, type)


func match_direction(coord, direction, type):
	while match_single(coord + direction, type):
		coord += direction


func match_single(coord, type):
	var piece := get_piece.call(coord) as Piece
	if piece and piece.matchable and piece.matchable.type==type and piece.state==Piece.State.IDLE:
		matches.append(piece)
		return true
	return false


func ortho(v) -> Vector2i:
	return Vector2i(Vector2(v).orthogonal()) # Vector2i(v.y, v.x)
