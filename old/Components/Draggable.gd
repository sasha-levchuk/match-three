class_name Draggable extends Node
@onready var block := owner as Block


func _ready():
	block.input_event.connect(_on_input_event)
	block.mouse_exited.connect(_on_mouse_exited)


func _on_input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton:
		if event.is_pressed() and block.state == Block.State.IDLE:
			block.z_index = 1
			block.state = Block.State.DRAGGED
		if event.is_released() and block.state == Block.State.DRAGGED:
			if block.powerup:
				block.powerup.trigger()
			else:
				reset_position()
	elif event is InputEventMouseMotion:
		if block.state == Block.State.DRAGGED:
			block.sprite.position += event.relative


func _on_mouse_exited():
	if not block.state == Block.State.DRAGGED: return
	var mouse := block.get_local_mouse_position()
	var direction := Vector2i.ZERO
	var axis := mouse.abs().max_axis_index()
	direction[axis] = sign(mouse[axis]) as int
	var neighbor := Game.get_block(block.posi+direction)
	if neighbor and neighbor.draggable:
		var coordinator := Coordinator.new(block, neighbor)
		block._on_swap(direction, coordinator)
		neighbor._on_swap(-direction, coordinator)
	else:
		reset_position()


func reset_position():
	block.state = Block.State.BUSY
	var tween = create_tween()
	tween.tween_property(block.sprite, 'position', Vector2.ZERO, 0.2)
	await tween.finished
	block.z_index = 0
	block.gravity.fall()


class Coordinator:
	var neighbors: Dictionary[Block, Block]
	var counter := 0
	var result := false
	signal done

	func combine_results(_result: bool) -> bool:
		counter += 1
		if _result: result = true
		if counter == 2:
			done.emit()
		else:
			await done
		return result

	func _init(block1: Block, block2: Block):
		neighbors[block1] = block2
		neighbors[block2] = block1
