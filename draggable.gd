class_name Draggable
extends Node
@onready var block := owner as Block


func _on_input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton:
		if event.is_pressed() and block.state == Block.State.IDLE:
			block.z_index += 1
			block.state = Block.State.HELD
		if event.is_released() and block.state == Block.State.HELD:
			if block.powerup:
				block.powerup.trigger()
			else:
				reset_position()
	elif event is InputEventMouseMotion:
		if block.state == Block.State.HELD:
			block.sprite.position += event.relative


func _on_mouse_exited():
	if block.state == Block.State.HELD:
		var v := block.get_local_mouse_position()
		v = Vector2(sign(v.x), 0) if abs(v.x) > abs(v.y) else Vector2(0, sign(v.y))
		Global.swap_requested.emit( block, v )


func reset_position():
	block.state = Block.State.RETURNING
	var tween := create_tween()
	tween.tween_property( block.sprite, 'position', Vector2.ZERO, 0.2 )
	tween.tween_callback(func():
		block.z_index = 0
		block.state = Block.State.IDLE
		block.check_and_fall()
	)
