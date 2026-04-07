class_name Board extends TileMapLayer
static var slots: Dictionary[Vector2i, Slot]
static var instance: Board
static var spawned_pieces: Array[Piece]
static var TILE_SIZE: Vector2
static var ZOOM: Vector2
signal swap_processed( is_success: bool )


func _ready():
	instance = self
	TILE_SIZE = tile_set.tile_size
	spawned_pieces.resize(10)
	await get_tree().process_frame
	for coord: Vector2i in get_used_cells():
		await get_tree().process_frame
		slots[coord].refill()


static func get_piece_above(coord: Vector2i) -> Piece:
	#prints('piece requested at coord', coord)
	while coord.y > 0:
		coord.y -= 1
		match slots[coord].state:
			Slot.State.READY, Slot.State.FALLING:
				var piece := slots[coord].piece
				slots[coord].refill()
				return piece
			Slot.State.SWAPPING, Slot.State.DRAGGING, Slot.State.DELETING:
				return null
	return spawn_piece(coord.x)


static func spawn_piece(col: int) -> Piece:
	var piece := load("res://piece.tscn").instantiate() as Piece
	var prev_piece := spawned_pieces[col]
	if prev_piece and prev_piece.global_position.y < TILE_SIZE.y/2:
		piece.position = prev_piece.global_position + TILE_SIZE*Vector2.UP
		piece.speed = prev_piece.speed
	else:
		piece.position = Vector2(col, -1)*TILE_SIZE + TILE_SIZE/2
	#prints('spawning piece', piece.name, 'at', piece.position, 'col', col)
	piece.setup_matchable()
	instance.add_child(piece)
	spawned_pieces[col] = piece
	return piece


static func spawn_powerup(coord: Vector2i, type: Powerup.Type):
	slots[coord].piece.queue_free()
	var piece := load("res://piece.tscn").instantiate() as Piece
	instance.add_child(piece)
	slots[coord].piece = piece
	piece.position = Vector2(coord)*TILE_SIZE + TILE_SIZE/2
	piece.setup_powerup(type)
	prints('spawn powerup', piece.powerup, 'at', coord)


static func append_at(arr: Array[Slot], type: Piece.Matchable.Type, coord: Vector2i) -> bool:
	var slot := slots.get(coord) as Slot
	if slot and slot.state==Slot.State.READY and \
	slot.piece.matchable and slot.piece.matchable.type==type:
		arr.append(slot)
		return true
	return false


static func match_toward(coord: Vector2i, type: Piece.Matchable.Type, direction: Vector2i) -> Array[Slot]:
	var matches: Array[Slot]
	while append_at(matches, type, coord+direction):
		coord += direction
	return matches


static func match_at(coord: Vector2i, type: Piece.Matchable.Type):
	var up := match_toward(coord, type, Vector2i.UP)
	var down := match_toward(coord, type, Vector2i.DOWN)
	var vertical := (up + down) as Array[Slot]
	var left := match_toward(coord, type, Vector2i.LEFT)
	var right := match_toward(coord, type, Vector2i.RIGHT)
	var horizontal := (left + right) as Array[Slot]
	var matches: Array[Slot]
	if horizontal.size()>=4 or vertical.size()>=4:
		matches = horizontal + vertical
		spawn_powerup(coord, Powerup.Type.DISCOBALL)
	elif horizontal.size()>=2 and vertical.size()>=2:
		matches = horizontal + vertical
		spawn_powerup(coord, Powerup.Type.TNT)
	elif horizontal.size()>=3:
		matches = horizontal
		spawn_powerup(coord, Powerup.Type.ROCKETV)
	elif vertical.size()>=3:
		matches = vertical
		spawn_powerup(coord, Powerup.Type.ROCKETH)
	else:
		var v := Vector2i.ONE
		for i in 4:
			v = Vector2i(v.y, -v.x)
			var arr := [] as Array[Slot]
			if append_at(arr, type, coord+v) and \
			append_at(arr, type, coord+Vector2i(v.x, 0)) and \
			append_at(arr, type, coord+Vector2i(0, v.y)):
				append_at(arr, type, coord+Vector2i(v.x*2, 0))
				append_at(arr, type, coord+Vector2i(0, v.y*2))
				matches = arr
				spawn_powerup(coord, Powerup.Type.FAN)
				break
	if not matches:
		if horizontal.size() >= 2:
			matches = horizontal
			matches.append(slots[coord])
		elif vertical.size() >= 2:
			matches = vertical
			matches.append(slots[coord])
	if matches:
		for slot: Slot in matches:
			slot.delete()
		return true
	return false
