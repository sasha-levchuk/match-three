class_name Slot extends Area2D
enum State{EMPTY, FALLING, DRAGGING, SWAPPING, RETURNING, DELETING, READY}
var state: State:
	set(new_state):
		state = new_state
		if not piece: return
		%Label.text = State.keys()[state] + ' ' + piece.name
		piece.modulate = {State.EMPTY:Color.MAGENTA, State.FALLING:  Color.YELLOW, 
					State.DRAGGING:   Color.GREEN,   State.SWAPPING: Color.BLUE, 
					State.RETURNING:  Color.RED,     State.DELETING: Color.ORANGE,
					State.READY:      Color.WHITE    }[state]
var piece: Piece
@onready var coord := Vector2i(position/%CollisionShape2D.shape.get_rect().size)
signal piece_landed


func _ready():
	Board.slots[coord] = self


func _input_event(_viewport: Viewport, event: InputEvent, _idx: int):
	if event is InputEventMouseButton:
		if event.is_pressed() and state == State.READY:
			state = State.DRAGGING
			piece.z_index = 1
		if event.is_released() and state == State.DRAGGING:
			state = State.RETURNING
			await piece.snap(position)
			state = State.READY
	elif event is InputEventMouseMotion:
		if state == State.DRAGGING:
			piece.sprite.position += event.relative / Board.ZOOM


func _mouse_exit():
	z_index = 0
	if state != State.DRAGGING: return
	var mouse := get_local_mouse_position()
	var axis := mouse.abs().max_axis_index()
	var direction := Vector2i.ZERO
	direction[axis] = sign(mouse[axis]) as int
	var slot := Board.slots.get(coord+direction) as Slot
	if slot and slot.state==State.READY:
		var result := [false]
		slot.receive_piece(piece, result)
		await receive_piece(slot.piece, result)
		await get_tree().process_frame
		if result[0] == false:
			prints('swap failed')
			slot.receive_piece(piece)
			receive_piece(slot.piece)
	else:
		state = State.RETURNING
		await piece.snap(position)
		state = State.READY


func refill():
	state = State.EMPTY
	piece = Board.get_piece_above(coord)
	while not piece:
		await get_tree().create_timer(0.1).timeout
		piece = Board.get_piece_above(coord)
	piece.set_process(true)
	piece.fall_target = position
	piece.landed = piece_landed
	state = State.FALLING
	await piece_landed
	if not piece.matchable or not Board.match_at(coord, piece.matchable.type):
		state = State.READY


func receive_piece(_piece: Piece, result_container:=[]):
	state = State.SWAPPING
	await get_tree().process_frame
	piece = _piece
	await piece.snap(position)
	state = State.READY
	if result_container:
		var is_success = true
		if piece.matchable:
			is_success = Board.match_at(coord, piece.matchable.type)
		result_container[0] = is_success or result_container[0]


func delete():
	state = State.DELETING
	await piece.delete()
	refill()
