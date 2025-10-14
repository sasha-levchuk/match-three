extends Control

@export var SIZE := Vector2i(6,6)
@export var piece_scene: PackedScene
@export var rules: Array[Rule]
var n_pieces_total := 0


func _ready():
	Rule.get_piece = get_piece
	Event.piece_deleted.connect(on_piece_deleted)
	Event.piece_arrived.connect(on_piece_arrived)
	Event.piece_dragged.connect(on_piece_dragged)
	Event.match_processed.connect(on_match_processed)
	set_process(false)
	holes.resize(SIZE.x)
	holes.fill(0)
	for x in SIZE.x:
		for y in SIZE.y:
			on_piece_deleted(Vector2i(x,y))


func match_coord(piece: Piece):
	prints('matching coord', piece.coord)
	for rule: Rule in rules:
		var matches := rule.match_around(piece.coord, piece.type)
		if matches: 
			prints('match found at', matches)
			Event.match_processed.emit(piece, true)
			piece.delete()
			while matches:
				matches.pop_back().delete()
			return
	Event.match_processed.emit(piece, false)


func get_piece(coord: Vector2i) -> Piece:
	for piece in get_children():
		if piece.coord==coord:
			return piece
	return null


func on_piece_arrived(piece: Piece):
	prints(piece, 'arrived at', piece.coord)
	match_coord(piece)


func on_piece_dragged(piece: Piece, where_to: Vector2i):
	prints('dragged', piece, 'from', piece.coord, 'to', where_to)
	var swap_piece: Piece = get_piece(where_to)
	if swap_piece and swap_piece.state==Piece.State.IDLE: 
		swapped_pairs.set([piece, swap_piece], [])
		swap(piece, swap_piece)
	else:
		piece.move(piece.coord)


func swap(piece1: Piece, piece2: Piece):
	piece1.destination = piece2.coord
	piece2.destination = piece1.coord


var swapped_pairs: Dictionary[Array, Array] #Dictionary[Array[Piece], Array[bool]]
func on_match_processed(piece: Piece, success: bool):
	for pair: Array[Piece] in swapped_pairs:
		if pair.has(piece): 
			var results := swapped_pairs[pair]
			results.append(success)
			if results.size()==2:
				if not results[0] and not results[1]:
					prints('failed swap at', pair)
					swap(pair[0], pair[1])
				swapped_pairs.erase(pair)
				break


var holes: Array[int]
func on_piece_deleted(coord: Vector2i):
	var column := coord.x
	holes[column] += 1
	if true:
		var where_from := Vector2i(column, SIZE.y-1+holes[column])
		var piece: Piece = piece_scene.instantiate()
		add_child(piece)
		n_pieces_total += 1
		piece.id = n_pieces_total
		piece.type = Piece.Type.values().pick_random()
		piece.position = piece.to_world(where_from)
		piece.coord = where_from
		piece.destination = where_from
		piece.self_modulate = piece.TypeColor[piece.type]
		piece.update_name()
		prints('spawned', piece, 'at', where_from)
	await get_tree().process_frame
	holes[column] -= 1
	for piece in get_children():
		if piece.coord.x==coord.x and piece.coord.y>coord.y:
			piece.destination -= Vector2i(0,1)
