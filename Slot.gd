class_name Slot extends Area2D

var coord: Vector2i
var block: Block
var is_dragging := false
var is_idle := false


func _input_event(__, event: InputEvent, ___) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and block and is_idle and not is_dragging:
			is_dragging = true
			is_idle = false
			block.sprite.z_index = 1
			block.sprite.scale *= 1.05
		elif event.is_released() and is_dragging:
			is_dragging = false
			if block is Explosive:
				Event.explosive_triggered(coord, block.type)
			else:
				await block.sprite.animate_reset().finished
				is_idle = true
	elif event is InputEventMouseMotion and is_dragging:
		block.sprite.offset += event.relative / Global.zoom


func _mouse_exit() -> void:
	if not is_dragging: return
	is_dragging = false
	var mouse := get_local_mouse_position()
	var direction := mouse/mouse.abs()[mouse.abs().max_axis_index()] as Vector2i
	var move := Move.new()
	move.from = coord
	move.to = coord + direction
	move.slot1 = self
	move.unhandled.append(move.from)
	move.unhandled.append(move.to)
	Event.move.emit(move)


func delete():
	is_idle = false
	await block.sprite.animate_delete().finished
	block.queue_free()
	block = null
	Event.cascade.emit(coord)


func spawn_rune(type: Explosive.Type):
	if type == Explosive.Type.NONE: 
		delete()
		return
	block.queue_free()
	block = Explosive.scenes[type].instantiate()
	add_child(block)


func take_block_move(new_block: Block, tween := create_tween()):
	tween.tween_property(new_block, 'global_position', global_position, BlockSprite.TWEEN_TIME	)
	tween.tween_callback(func():
		block = new_block
	)



