class_name Board extends TileMapLayer
static var slots: Dictionary[Vector2i, Slot]
static var instance: Board
var ROWS: int
var COLS: int
static var spawned_pieces: Array[Piece]
static var TILE_SIZE: Vector2
static var ZOOM: Vector2
signal swap_processed( is_success: bool )


func _ready():
	instance = self
	TILE_SIZE = tile_set.tile_size
	for coord: Vector2i in get_used_cells():
		COLS = max(coord.x+1, COLS)
		ROWS = max(coord.y+1, ROWS)
	spawned_pieces.resize(COLS)
	prints(COLS, ROWS)
	await get_tree().process_frame
	for row in range(ROWS-1,-1,-1):
		for col in COLS:
			slots[Vector2i(col, row)]._on_piece_exiting()


static func get_piece_above(coord: Vector2i) -> Piece:
	prints('piece requested at coord', coord)
	while coord.y > 0:
		coord.y -= 1
		match slots[coord].state:
			Slot.State.READY, Slot.State.FALLING:
				return slots[coord].piece
			Slot.State.SWAPPING, Slot.State.DRAGGING:
				return null
	return spawn_block(coord.x)


static func spawn_block(col: int) -> Piece:
	var piece := load("res://piece.tscn").instantiate() as Piece
	piece.position = TILE_SIZE * Vector2(0.5+col, -0.5)
	var prev_piece := spawned_pieces[col]
	if prev_piece and prev_piece.position.y-piece.position.y < TILE_SIZE.y:
		piece.position = prev_piece.global_position - Vector2(0,TILE_SIZE.y)
		piece.velocity = prev_piece.velocity
	prints('spawning piece', piece.name, 'at', piece.position, 'col', col)
	instance.add_child(piece)
	spawned_pieces[col] = piece
	return piece
