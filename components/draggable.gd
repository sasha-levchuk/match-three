class_name Draggable
var drag_center: Vector2
var drag_offset: Vector2
var owner: Piece


func _init(_owner: Piece):
	owner = _owner
	owner.button_down.connect(_on_button_down)
	owner.button_up.connect(_on_button_up)


func _on_button_down():
	drag_center = owner.global_position + owner.size/2
	drag_offset = owner.get_local_mouse_position()
	owner.set_process(true)
	owner.state = Piece.State.DRAGGING


func _process():
	var mouse := owner.get_global_mouse_position()
	owner.global_position = mouse - drag_offset
	var offset: Vector2i = ((mouse-drag_center)/owner.size*Vector2(2,-2)).limit_length(sqrt(2))
	if offset and not offset.x * offset.y:
		owner.set_process(false)
		#prints(self, 'emits the dragged signal towards', offset)
		Event.piece_dragged.emit(owner, owner.coord + offset)


func _on_button_up():
	if owner.state == Piece.State.DRAGGING:
		owner.set_process(false)
		owner.drag(owner.coord)
