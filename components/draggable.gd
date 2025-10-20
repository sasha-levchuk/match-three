class_name Draggable extends Node
var drag_center: Vector2
var drag_offset: Vector2
signal dragged


func _ready():
	owner.button_down.connect(_on_button_down)
	owner.button_up.connect(_on_button_up)


func _on_button_down():
	owner.state = Piece.State.DRAGGING
	owner.z_index += 2
	drag_center = owner.global_position + owner.size/2
	drag_offset = owner.get_local_mouse_position()
	set_process(true)


func _process(_delta):
	var mouse := owner.get_global_mouse_position() as Vector2
	owner.global_position = mouse - drag_offset
	var offset: Vector2i = ((mouse-drag_center)/owner.size*Vector2(2,-2)).limit_length(sqrt(2))
	if offset and not offset.x * offset.y:
		owner.destination += offset
		owner.disabled = true


func _on_button_up():
	if is_processing():
		set_process(false)
		owner.z_index -= 2
		dragged.emit()
