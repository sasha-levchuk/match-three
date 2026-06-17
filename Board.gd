class_name Board extends TileMapLayer
var slots: Dictionary[Vector2i, Slot]
var spawners: Dictionary[Vector2i, Spawner]
var explosions_manager := preload("res://explosions_manager.gd").new(slots)
var match_manager := preload("res://match_manager.gd").new(slots)


func _ready() -> void:
	child_entered_tree.connect(func(child: Node2D):
		var coord := local_to_map(child.position)
		if child is Slot:
			slots[coord] = child
			child.coord = coord
			await get_tree().create_timer(randf_range(.1, .5)).timeout
			cascade(coord)
		elif child is Spawner:
			spawners[coord] = child
	)
	Event.collision.connect(_on_collision)
	Event.move.connect(_on_move)
	Event.cascade.connect(cascade)
	Event.test.connect(func():
		for coord in slots:
			if not randi()%4:
				var slot := slots.get(coord) as Slot
				if slot.block:
					slot.delete()
	)


func cascade(coord: Vector2i):
	coord += Vector2i.UP
	if not coord in slots:
		spawners[coord].spawn()
		return
	var slot := slots[coord]
	if slot.is_idle:
		slot.is_idle = false
		var block := slots[coord].block
		block.set_process(true)
		prints('releasing', block.name, 'from', coord)
		slots[coord].block = null
	cascade(coord)


func _on_collision(block: Block):
	var coord := local_to_map(block.global_position)
	if not coord in slots: return
	var coord_below := coord + Vector2i.DOWN
	if coord_below in slots and not slots[coord_below].block: return
	#prints('assigning', block.name, 'to', slots[coord].name)
	var slot := slots[coord]
	slot.block = block
	slot.is_idle = true
	block.set_process(false)
	block.speed = 0
	block.reparent(slots[coord])
	block.position = Vector2.ZERO
	match_manager.handle_single(coord)


func _on_move(move: Move):
	if is_valid(move):
		move.slot2 = slots[move.to]
		await animate(move)
		match_manager.handle(move)
		if move.is_successful:
			finalize(move)
		else:
			revert(move)
	else:
		cancel(move)


func is_valid(move: Move):
	return move.to in slots and slots[move.to].is_idle


func animate(move: Move):
	var tween := move.slot1.block.sprite.animate_reset()
	move.slot1.take_block_move(move.slot2.block, tween)
	move.slot2.take_block_move(move.slot1.block, tween)
	return tween.finished


func finalize(move: Move):
	if move.unhandled:
		slots[move.unhandled[0]].is_idle = true


func revert(move: Move):
	await animate(move)
	move.slot1.block.is_idle = true
	move.slot2.block.is_idle = true


func cancel(move: Move):
	await move.slot1.block.reset_after_drag()
	move.slot1.block.is_idle = true
