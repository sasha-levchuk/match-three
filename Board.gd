extends TileMapLayer
var slots: Dictionary[Vector2i, Slot]
var sides := [Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT]
@onready var tilesize := tile_set.tile_size as Vector2
var prev_pieces:Array[Piece]


func _ready():
	prev_pieces.resize(10)
	await get_tree().process_frame
	for slot: Slot in get_children():
		var coord := Vector2i(slot.position/tilesize)
		slots[coord] = slot
		slot.piece_requested.connect(_on_piece_requested.bind(coord))
		slot.piece_landed.connect(_on_piece_landed.bind(coord))
		slot.piece_moved.connect(_on_piece_moved.bind(coord))
		prints('refilling slot', coord)
	for slot: Slot in get_children():
		slot.piece_requested.emit()


func _on_piece_requested(coord: Vector2i):
	var row := coord.y
	while row:
		row -= 1
		var piece := slots[Vector2i(coord.x, row)].piece
		if not piece: continue
		if piece.state==Piece.State.IDLE or piece.state==Piece.State.FALLING:
			piece.departed.emit()
			slots[coord].acquire_piece(piece)
			return
		return
	slots[coord].acquire_piece(spawn_piece(coord.x))


func _on_piece_landed(piece: Piece, coord: Vector2i):
	var is_success := is_match(coord, piece.type)
	if not is_success:
		piece.state = Piece.State.IDLE


func is_match(coord: Vector2i, type: Piece.Type) -> bool:
	var matches: Dictionary[Vector2i, Array]
	for side: Vector2i in sides:
		matches[side] = []
		var counter := 1
		while match_and_append(matches[side], coord+side*counter, type):
			counter += 1
	var result: Array
	var horizontal := matches[Vector2i.LEFT] + matches[Vector2i.RIGHT]
	var vertical := matches[Vector2i.UP] + matches[Vector2i.DOWN]
	var all := horizontal + vertical
	if horizontal.size() >= 4 or vertical.size() >= 4:
		prints('matched 5')
		result = all
	elif horizontal.size() >= 2 and vertical.size() >= 2:
		prints('matched tnt')
		result = all
	elif horizontal.size() >= 3:
		prints('matched rocketv')
		result = horizontal
	elif vertical.size() >= 3:
		prints('matched rocketh')
		result = vertical
	else:
		pass
		#for i in 4:
			#var direction1 := directions[i]
			#var direction2 := directions[(i+1)%4]
			#var diag := direction1 + direction2
			#matches[direction] = []
			
	if result:
		result.append(slots[coord].piece)
		prints('matches', result)
		for piece: Piece in result:
			piece.delete()
		return true
	return false


func match_and_append(arr: Array, coord: Vector2i, type: Piece.Type)->bool:
	if is_valid(coord) and slots[coord].piece.type==type:
		arr.append(slots[coord].piece)
		return true
	return false


func _on_piece_moved(direction: Vector2i, coord: Vector2i):
	if is_valid(coord+direction):
		prints('move valid')
	else:
		slots[coord].piece.place_back()


func is_valid(coord: Vector2i):
	var slot := slots.get(coord) as Slot
	return slot and slot.piece and slot.piece.state == Piece.State.IDLE


func spawn_piece(col: int) -> Piece:
	var new_piece = load("res://piece.tscn").instantiate() as Piece
	add_child(new_piece)
	var pos := Vector2.RIGHT*col*tilesize + tilesize/2 + tilesize*Vector2.UP
	var piece := prev_pieces[col]
	if piece and is_instance_valid(piece) and piece.position.y-pos.y<tilesize.y:
		pos = piece.position + tilesize*Vector2.UP
	new_piece.position = pos
	prev_pieces[col] = new_piece
	return new_piece
