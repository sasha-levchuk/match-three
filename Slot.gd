class_name Slot extends Sprite2D
var piece: Piece
signal piece_departed()
signal piece_landed
signal piece_triggered
signal piece_moved(direction: Vector2i)
signal piece_requested()


func _ready():
	piece_departed.connect(func():
		piece = null
		while not piece:
			piece_requested.emit()
			await get_tree().create_timer(0.1).timeout
		)


func acquire_move(_piece: Piece):
	await _piece.move(position)
	piece = _piece
	connect_signals()


func acquire_fall(_piece: Piece):
	piece = _piece
	piece.landed = piece_landed
	piece.fall(position)
	connect_signals()


func connect_signals():
	piece.triggered = piece_triggered
	piece.moved = piece_moved
	piece.departed = piece_departed
