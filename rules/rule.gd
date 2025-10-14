class_name Rule
extends Resource

@export var name: String
@export var min_size: int
@export var reward: Powerup.Type
@export var directions: Array[Vector2i]
var RewardMatcher: Dictionary[Powerup.Type,Callable] = {
	Powerup.Type.NONE: match_line,
	Powerup.Type.DISCOBALL: match_line,
}
var matcher: Callable = RewardMatcher[reward]
var RewardMatcherOptional: Dictionary[Powerup.Type,Callable] = {
	Powerup.Type.DISCOBALL: func(coord, direction, type) -> Array[Piece]:
		return match_direction(coord, ortho(direction), type) + match_direction(coord, -ortho(direction), type),
	Powerup.Type.NONE: func(..._args) -> Array[Piece]: return [] as Array[Piece],
}
var optional: Callable = RewardMatcherOptional[reward]
static var get_piece: Callable


func match_around(coord: Vector2i, type: Piece.Type) -> Array[Piece]:
	var matches: Array[Piece]
	for direction in directions:
		matches = matcher.call(coord, direction, type)
		if matches.size()+1 >= min_size:
			prints('matched', name, 'coord', coord, 'type', type, 'direction', direction, 'matches:', matches)
			matches.append_array(optional.call(coord, direction, type))
			return matches
	return []


func match_line(coord, direction, type) -> Array[Piece]:
	var matches: Array[Piece]
	matches.append_array(match_direction(coord, direction, type))
	matches.append_array(match_direction(coord, -direction, type))
	return matches


func match_direction(coord, direction, type) -> Array[Piece]:
	var matches: Array[Piece]
	while true:
		coord += direction
		var piece := match_single(coord, type)
		if piece:
			matches.append(piece)
		else:
			break
	return matches


func match_single(coord, type) -> Piece:
	var piece := get_piece.call(coord) as Piece
	if piece and piece.type==type and piece.state==Piece.State.IDLE:
		return piece
	return null
	


func is_type1(coord: Vector2i, type: Piece.Type) -> bool:
	var piece := get_piece.call(coord) as Piece
	return piece and piece.type==type


func ortho(v) -> Vector2i:
	return Vector2i(Vector2(v).orthogonal()) # Vector2i(v.y, v.x)


"
	Powerup.Type.TNT: func(coord, type):
		var matches_v := match_line( coord, Vector2i.DOWN, type )
		var matches_h := match_line( coord, Vector2i.LEFT, type )
		if matches_v.size()+1>=3 and matches_h.size()+1>=3:
			deletion_queue.append_array(matches_v + matches_h)
			prints('tnt', coord)
			return true,
	Powerup.Type.ROCKET: func(coord, type):
		for direction in [Vector2i.LEFT, Vector2i.DOWN]:
			var matches := match_line(coord, direction, type)
			if matches.size()+1 >= 4:
				deletion_queue.append_array(matches)
				prints('rocket', coord)
				return true,
	Powerup.Type.FAN: func(coord, type):
		for offset in [Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP, Vector2i.RIGHT]:
			var matches: Array[Piece]
			for i in 3:
				if match_at(coord+offset, type):
					matches.append(pieces[coord+offset])
				offset += ortho(offset)
			if matches.size()+1 == 4:
				deletion_queue.append_array(matches)
				prints('fan', coord)
				return true,
	Powerup.Type.NONE: func(coord, type):
		for direction in [Vector2i.LEFT, Vector2i.DOWN]:
			var matches := match_line(coord, direction, type)
			if matches.size()+1 >= 3:
				deletion_queue.append_array(matches)
				prints('found a three at', coord, matches)
				return matches
"
