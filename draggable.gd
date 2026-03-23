class_name Draggable
extends Node
@onready var block := owner as Block
var tween: Tween


func _ready():
	block.input_event.connect(_on_input_event)
	block.mouse_exited.connect(_on_mouse_exited)


func _on_input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton:
		if event.is_pressed() and block.state == Block.State.IDLE:
			block.z_index += 1
			block.state = Block.State.DRAGGED
		if event.is_released() and block.state == Block.State.DRAGGED:
			if block.powerup:
				block.powerup.trigger()
			else:
				block.reset_position()
	elif event is InputEventMouseMotion:
		if block.state == Block.State.DRAGGED:
			block.sprite.position += event.relative


func _on_mouse_exited():
	if not block.state == Block.State.DRAGGED: return
	var mouse := block.get_local_mouse_position()
	var direction := Vector2i.ZERO
	var axis := mouse.abs().max_axis_index()
	direction[axis] = sign(mouse[axis]) as int
	var neighbor := block.raycaster.get_neighbor(direction)
	if neighbor and neighbor.draggable:
		block._on_swap(direction, neighbor)
		neighbor._on_swap(-direction, block)
	else:
		block.reset_position()
