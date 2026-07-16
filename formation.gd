class_name Formation

static var tiles: Dictionary[Vector2i, Tile]

var origin: Vector2i
var match_type: Matchable.Type
var vertical: Array[Vector2i]
var horizontal: Array[Vector2i]

var is_found: bool
var matches: Array[Vector2i]
var has_reward: bool
var reward: Explosive.Type


func _init(_coord: Vector2i):
	origin = _coord
	match_type = tiles[origin].type as Matchable.Type
	horizontal = match_line(Vector2i.RIGHT)
	vertical = match_line(Vector2i.DOWN)
	for type: Explosive.Type in rules:
		rules[type].call()
		if matches:
			is_found = true
			if type != Explosive.Type.NONE:
				has_reward = true
				reward = type
			return


var rules: Dictionary[Explosive.Type, Callable] = {
	Explosive.Type.DISCO: func():
		if horizontal.size() >= 4 or vertical.size() >= 4:
			matches.append_array(horizontal + vertical),
	Explosive.Type.TNT: func():
		if horizontal.size() >= 2 and vertical.size() >= 2:
			matches.append_array(horizontal + vertical),
	Explosive.Type.ROCKETV: func():
		if horizontal.size() >= 3:
			matches = horizontal,
	Explosive.Type.ROCKETH: func():
		if vertical.size() >= 3:
			matches = vertical,
	Explosive.Type.WINGS: func():
		const dirs := [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP]
		for direction: Vector2i in dirs:
			var ortho := Vector2i(direction.y, -direction.x)
			var offsets := [direction, ortho, direction+ortho] as Array[Vector2i]
			var coords := match_many(offsets)
			if coords.size() < 3: continue
			offsets = [direction*2, ortho*2, -ortho, -direction]
			coords.append_array(match_many(offsets as Array[Vector2i]))
			matches = coords
			return,
	Explosive.Type.NONE: func():
		if horizontal.size() >= 2:
			matches = horizontal
			matches.append(origin)
		elif vertical.size() >= 2:
			matches = vertical
			matches.append(origin)
}


func match_line(direction: Vector2i) -> Array[Vector2i]:
	var coords: Array[Vector2i]
	match_direction(direction, coords)
	match_direction(-direction, coords)
	return coords


func match_direction(direction: Vector2i, coords: Array[Vector2i], coord:=origin):
	coord += direction
	if match_single(coord):
		coords.append(coord)
		match_direction( direction, coords, coord)


func match_single(coord: Vector2i) -> bool:
	var tile := tiles.get(coord) as Tile
	if tile:
		return tile is Matchable and tile.is_idle and tile.type==match_type
	return false


func match_many(offsets: Array[Vector2i]) -> Array[Vector2i]:
	var coords: Array[Vector2i]
	for offset: Vector2i in offsets:
		if match_single(origin + offset):
			coords.append(origin + offset)
	return coords
