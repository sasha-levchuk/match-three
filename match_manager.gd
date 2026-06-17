class_name MatchManager
var slots: Dictionary[Vector2i, Slot]
var rules: Dictionary[Explosive.Type, Callable] = {
	Explosive.Type.DISCO: func(params: Params):
		if params.horizontal.size() >= 4 or params.vertical.size() >= 4:
			params.matches = params.horizontal + params.vertical,
	Explosive.Type.TNT: func(params: Params):
		if params.horizontal.size() >= 2 and params.vertical.size() >= 2:
			params.matches = params.horizontal + params.vertical,
	Explosive.Type.ROCKETV: func(params: Params):
		if params.horizontal.size() >= 3:
			params.matches = params.horizontal,
	Explosive.Type.ROCKETH: func(params: Params):
		if params.vertical.size() >= 3:
			params.matches = params.vertical,
	Explosive.Type.WINGS: func(params: Params):
		var dirs := [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP]
		for direction: Vector2i in dirs:
			var ortho := Vector2i(direction.y, -direction.x)
			var offsets := [direction, ortho, direction+ortho]
			var matches := match_many(params.type, params.coord, offsets)
			if matches.size() == 3:
				offsets = [direction*2, ortho*2, -ortho, -direction]
				matches.append_array(match_many(params.type, params.coord, offsets))
				params.matches = matches,
	Explosive.Type.NONE: func(params: Params):
		if params.horizontal.size() >= 2:
			params.matches = params.horizontal
		elif params.vertical.size() >= 2:
			params.matches = params.vertical
}


func _init(_slots) -> void:
	slots = _slots


class Params:
	var type: Matchable.Type
	var coord: Vector2i
	var horizontal: Array[Slot]
	var vertical: Array[Slot]
	var matches: Array[Slot]


func handle(move: Move):
	for i: int in [1, 0]:
		var coord := move.unhandled[i]
		if handle_single(coord):
			move.is_successful = true
			move.unhandled.erase(coord)


func handle_single(coord: Vector2i) -> bool:
	var params := Params.new()
	params.coord = coord
	params.type = slots[coord].block.type as Matchable.Type
	params.horizontal = match_line(params, Vector2i.RIGHT)
	params.vertical = match_line(params, Vector2i.DOWN)
	for type: Explosive.Type in rules:
		rules[type].call(params)
		if params.matches:
			prints('matched', type, 'at', params.matches)
			for slot: Slot in params.matches:
				slot.delete()
			slots[coord].spawn_explosive(type)
			return true
	return false


func match_line(params: Params, direction: Vector2i) -> Array[Slot]:
	var matches: Array[Slot]
	match_direction(params, direction, matches)
	match_direction(params, -direction, matches)
	return matches


func match_direction(params: Params, offset: Vector2i, matches: Array[Slot]):
	var slot := match_single(params.type, params.coord+offset)
	if not slot: return
	matches.append(slot)
	match_direction(params, offset + offset.sign(), matches)


func match_single(type: Matchable.Type, coord: Vector2i) -> Slot:
	if coord in slots:
		var slot := slots[coord]
		if slot.block and slot.is_idle:
			var block := slot.block
			if block is Matchable and block.type==type:
				return slot
	return null


func match_many(type: Matchable.Type, origin: Vector2i, offsets: Array) -> Array[Slot]:
	var matches: Array[Slot]
	for offset: Vector2i in offsets:
		var slot := match_single(type, origin + offset)
		if slot:
			matches.append(slot)
	return matches
