extends Control
#TODO:
#currently there's a bug with pieces overlapping,
#possibly because of early swiping upon dragging a powerup piece.
@export var rules: Array[Rule]
@export var piece_scene: PackedScene
@export var SIZE_square := 6
@export var SIZE := Vector2i(SIZE_square, SIZE_square)
var deletion_batch: Array[Piece]


func _ready():
	for rule: Rule in rules:
		rule.setup()
	Rule.get_piece = get_piece
	Powerup.get_piece = get_piece
	await get_tree().create_timer(.5).timeout
	for x in SIZE.x:
		for y in SIZE.y:
			on_piece_destroyed(Vector2i(x,y))


# if both are powerups, combine them and play some animation i guess?
# store the reference to the second piece in the dragged piece
func on_drag_initiated(piece: Piece, where_to: Vector2i):
	var swap_piece: Piece = get_piece(where_to)
	if swap_piece and swap_piece.state==Piece.State.IDLE:
		piece.swap_piece = swap_piece
		swap_piece.drag(piece.coord)
		swap_piece.move_tween.tween_callback(on_drag_finished.bind(piece, swap_piece))
	else:
		piece.drag(piece.coord)


func on_drag_finished(piece1: Piece, piece2: Piece):
	var match_success := false
	if match_piece(piece1):
		match_success = true
	if match_piece(piece2):
		match_success = true
	if not match_success:
		piece1.move(piece2.coord)
		piece2.move(piece1.coord).tween_callback(on_drag_reversed.bind(piece1, piece2))


func match_piece(piece: Piece) -> bool:
	return rules.any(func(rule): return rule.match_piece(piece))


# check for possible holes underneath and swipe if needed
func on_drag_reversed(piece1, piece2):
	#find holes
	#think how the vertical drag pair is handled
	for piece: Piece in [piece1, piece2]:
		var holes := get_holes_underneath(piece.coord)
		if not holes: continue
		piece.swipe(holes)
		swipe_all_above(piece.coord, holes)
		for i in holes:
			spawn(find_next_free_spawn_slot(piece.coord.x), holes)


func get_holes_underneath(coord: Vector2i) -> int:
	var holes := 0
	while coord.y > 0:
		coord.y -= 1
		var piece := get_piece(coord)
		if piece:
			if piece.state != Piece.State.SWIPING or get_piece_by_dest(coord):
				break
		holes += 1
	return holes


func swipe_all_above(coord: Vector2i, height: int):
	# there are never holes between already summonned pieces because ...
	# ... every new hole immediately becomes a destination of a piece above
	while true:
		coord.y += 1
		var piece := get_piece_by_dest(coord)
		if piece and piece.can_swipe():
			piece.swipe(height)
		else:
			break


func on_piece_destroyed(coord: Vector2i):
	var holes := get_holes_underneath(coord) + 1 # plus the just destroyed one
	swipe_all_above(coord, holes)
	for i in holes:
		spawn(find_next_free_spawn_slot(coord.x), holes)


func find_next_free_spawn_slot(column: int):
	var height: int = 1
	var coord = Vector2i(column, SIZE.y-1+height)
	while get_piece(coord):
		height += 1
		coord.y += 1
	return coord


func spawn_powerup(coord: Vector2i, type: Powerup.Type):
	spawn(coord).init_powerup(type)


func spawn_matchable(coord: Vector2i):
	var type: Matchable.Type = Matchable.Type.values().pick_random()
	return spawn(coord).init_matchable(type)
	piece.init(coord, Matchable, type)
	piece.swipe(height)


func spawn(coord: Vector2i):
	var piece: Piece = piece_scene.instantiate()
	add_child(piece, true)
	piece.init(coord)
	piece.draggable.drag_initiated.connect(on_drag_initiated)
	piece.destroyed.connect(on_piece_destroyed)
	return piece


func get_piece(coord: Vector2i) -> Piece:
	for piece: Piece in get_children(): 
		if piece.coord==coord: 
			return piece
	return null


func get_piece_by_dest(coord: Vector2i) -> Piece:
	return get_children().filter(func(p):return p.destination==coord).pop_back()


#func swipe():
	#for column: int in SIZE.x:
		#var holes := 0
		#for row: int in SIZE.y:
			#var piece := get_piece_by_dest(Vector2i(column, row))
			#if piece:
				#if piece.can_swipe():
					#piece.swipe(holes)
				#else:
					#holes = 0
			#else:
				#holes += 1
		#var coord := Vector2i(column, SIZE.y)
		#var offset := 0
		#while get_piece(coord):
			#coord.y += 1
			#offset += 1
		#for i in holes:
			#spawn(coord, holes+offset)
			#coord.y += 1
