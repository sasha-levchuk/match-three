#TODO:
#make the rocket powerup into two subtypes - vertical and horizontal
#fix z-order issues
#add powerup behaviors
#currently there's a bug with pieces overlapping,
#possibly because of early swiping upon dragging a powerup piece.
extends Control

@export var SIZE_square := 6
@export var SIZE := Vector2i(SIZE_square, SIZE_square)
@export var piece_scene: PackedScene
@export var db: Resource
@export var matcher: Node
var deletion_batch: Array[Piece]


func _ready():
	Rule.get_piece = get_piece
	Powerup.get_piece = get_piece
	Event.piece_deleted.connect(on_piece_deleted)
	Event.piece_arrived.connect(on_piece_arrived)
	Event.piece_dragged.connect(on_piece_dragged)
	Event.match_processed.connect(on_match_processed)
	Event.powerup_triggered.connect(on_powerup_triggered)
	await get_tree().create_timer(.5).timeout
	swipe()


func get_piece(coord: Vector2i) -> Piece:
	for piece: Piece in get_children():
		if piece.coord==coord:
			return piece
	return null


func get_piece_by_dest(coord: Vector2i) -> Piece:
	return get_children().filter(func(p):return p.destination==coord).pop_back()


func on_piece_arrived(piece: Piece):
	pass


func on_piece_dragged(piece: Piece, where_to: Vector2i):
	var swap_piece: Piece = get_piece(where_to)
	if swap_piece and swap_piece.state==Piece.State.IDLE:
		drag_results.append(DragResult.new(piece, swap_piece))
		swap(piece, swap_piece)
	else:
		piece.place_back()


func swap(piece1: Piece, piece2: Piece):
	piece1.drag(piece2.coord)
	piece2.drag(piece1.coord)


var drag_results: Array[DragResult]
class DragResult:
	var counter := 0
	var pieces: Array[Piece]
	var matches: Array[Piece]
	func _init(p1, p2): 
		pieces.append_array([p1, p2])


func on_match_processed(piece: Piece, matches: Array[Piece]):
	for drag_result in drag_results:
		if drag_result.counter < 2 and drag_result.pieces.has(piece):
			drag_result.matches.append_array(matches)
			drag_result.counter += 1
			if drag_result.counter==2:
				if drag_result.matches.is_empty():
					swap(drag_result.pieces.pop_back(), drag_result.pieces.pop_back())
					drag_results.erase(drag_result)
			return
	if not matches.is_empty():
		#if we reach this point, it means that the match is from a swipe, not a drag
		match_results.append(MatchResult.new(piece, matches))


# to avoid conflict, we wait for all deletion animations to play out
# and send their signals here
# and only upon the last signal of the bunch we swipe the board
func on_piece_deleted(deleted_piece:Piece):
	for drag_result: DragResult in drag_results:
		if drag_result.counter==2 and deleted_piece in drag_result.matches:
			drag_result.matches.erase(deleted_piece)
			if drag_result.matches.is_empty(): # this is the last piece of the bunch
				drag_results.erase(drag_result)
				swipe()
			return
	# if this place is reached, the piece was deleted in a swipe
	for match_result: MatchResult in match_results:
		if match_result.matches.has(deleted_piece):
			match_result.matches.erase(deleted_piece)
			if match_result.matches.is_empty():
				match_results.erase(match_result)
				swipe()
			return
	swipe()


func swipe():
	prints('')
	for column: int in SIZE.x:
		var holes := 0
		for row: int in SIZE.y:
			var coord := Vector2i(column, row)
			var piece := get_piece_by_dest(coord)
			if piece and not piece.is_queued_for_deletion():
				if piece.state==Piece.State.DELETED or piece.state==Piece.State.DRAGGING:
					holes = 0
				else:
					piece.swipe(holes)
			else:
				holes += 1
		if true:
			var coord := Vector2i(column, SIZE.y)
			var offset := 0
			while get_piece(coord):
				coord.y += 1
				offset += 1
			for i in holes:
				spawn(coord, holes + offset)
				coord.y += 1


func spawn_powerup(coord: Vector2i, type: Powerup.Type):
	var piece := piece_scene.instantiate()
	add_child(piece, true)
	piece.init(coord, Powerup, type)


func spawn(coord: Vector2i, height:=0):
	var type: Matchable.Type = Matchable.Type.values().pick_random()
	var piece := piece_scene.instantiate()
	add_child(piece, true)
	piece.init(coord, Matchable, type)
	piece.swipe(height)


func on_powerup_triggered(_triggered_piece: Piece):
	pass
