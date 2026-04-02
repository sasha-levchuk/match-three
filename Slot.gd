class_name Slot extends Area2D
enum State{EMPTY, DRAGGING, SWAPPING, BUSY, READY, FALLING}
var state: State
var piece: Piece
@onready var coord := Vector2i(position/%CollisionShape2D.shape.get_rect().size)


func _ready():
	Board.slots[coord] = self
	child_exiting_tree.connect(_on_piece_exiting)


func _input_event(_viewport: Viewport, event: InputEvent, _idx: int):
	if event is InputEventMouseButton:
		if event.is_pressed() and state == State.READY:
			z_index = 1
			state = State.DRAGGING
		if event.is_released() and state == State.DRAGGING:
			await piece.snap()
			state = State.READY
	elif event is InputEventMouseMotion:
		if state == State.DRAGGING:
			piece.position += event.relative / Board.ZOOM


func _mouse_exit():
	z_index = 0
	if state != State.DRAGGING: return
	var mouse := get_local_mouse_position()
	var axis := mouse.abs().max_axis_index()
	var direction := Vector2i.ZERO
	direction[axis] = sign(mouse[axis]) as int
	var slot := Board.slots.get(coord+direction) as Slot
	if slot and slot.state==State.READY:
		slot.receive_piece(piece)
		await receive_piece(slot.piece)
		#var is_success := await Event.swap_processed as bool
		#if is_success:
			#return
	else:
		state = State.BUSY
		await piece.snap()
		state = State.READY


func _on_piece_exiting(_piece:Piece=null):
	if state==State.SWAPPING: return
	state = State.EMPTY
	piece = Board.get_piece_above(coord)
	while not piece:
		await get_tree().create_timer(0.1).timeout
		piece = Board.get_piece_above(coord)
	piece.reparent(self)
	piece.set_process(true)


func receive_piece(_piece: Piece):
	state = State.SWAPPING
	await get_tree().process_frame
	piece = _piece
	piece.reparent(self)
	await piece.snap()
	state = State.READY
