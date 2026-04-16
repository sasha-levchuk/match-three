class_name Slot extends Sprite2D
var piece: Piece
signal piece_departed()
signal piece_landed
signal piece_triggered
signal piece_moved(direction: Vector2i)
signal piece_requested()


func _ready():
	piece_departed.connect(_on_piece_departed)
	%ButtonTest.pressed.connect(func():piece.make_powerup(Piece.PowerupType.TNT))
	%ButtonClose.pressed.connect(func():
		if piece: 
			piece.delete()
		else:
			piece_departed.emit()
		)


func acquire_move(_piece: Piece):
	await _piece.move(position)
	connect_signals(_piece)


func connect_signals(_piece: Piece):
	piece = _piece
	piece.landed = piece_landed
	piece.triggered = piece_triggered
	piece.moved = piece_moved
	piece.departed = piece_departed
	piece.target = position


func _on_piece_departed():
	piece = null
	while not piece:
		piece_requested.emit()
		await get_tree().create_timer(0.1).timeout


func is_valid_target():
	return piece and piece.state == Piece.State.IDLE and piece.is_matchable
