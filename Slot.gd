class_name Slot extends Sprite2D
var piece: Piece
signal piece_departed()
signal piece_landed(type: Piece.Type)
signal piece_moved(direction: Vector2i)
signal piece_requested()


func _ready():
	piece_departed.connect(_on_piece_departed)
	%Button.pressed.connect(func():
		if piece: 
			piece.delete()
		else:
			piece_departed.emit()
		)


func acquire_piece(_piece: Piece):
	piece = _piece
	piece.landed = piece_landed
	piece.moved = piece_moved
	piece.departed = piece_departed
	piece.target = position
	piece.state = Piece.State.FALLING
	piece.set_process(true)


func _on_piece_departed():
	piece = null
	while not piece:
		piece_requested.emit()
		await get_tree().create_timer(0.1).timeout
