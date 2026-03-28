class_name Powerup
enum Type {DISCOBALL, TNT, ROCKETV, ROCKETH, FAN}
var type: Type
var block: Block


func _init(_block: Block, _type: Type):
	type = _type
	block = _block
	block.sprite.frame = 5 + type as int
	block.matchable.queue_free()
	block.matchable = null


func trigger():
	var offsets: Array[Vector2]
	block.sprite.frame = 10
	block.delete()
	match type:
		Type.DISCOBALL:
			var match_type := Matchable.Type.values().pick_random() as Matchable.Type
			for del_block in block.get_tree().get_nodes_in_group('blocks'):
				if not del_block.matchable: continue
				if not del_block.matchable.type==match_type: continue
				if not del_block.state == Block.State.IDLE: continue
				del_block.delete()
			block.delete()
			return
		Type.TNT:
			Game.tnt_exploded.emit()
			for x in 5:
				for y in 5:
					offsets.append(Vector2(x-2, y-2))
		Type.ROCKETV:
			for y in 20:
				offsets.append(Vector2(0, y-10))
		Type.ROCKETH:
			for x in 20:
				offsets.append(Vector2(x-10, 0))
		Type.FAN:
			offsets.append_array([Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT])
	for offset: Vector2i in offsets:
		var del_block := block.raycaster.get_block_at_point(offset)
		if not del_block: continue
		prints('del_block', del_block, offset, del_block.state_str)
		#if not del_block.state == Block.State.IDLE: continue
		if del_block.state != Block.State.IDLE: continue
		if del_block.powerup:
			del_block.powerup.trigger()
		else:
			del_block.delete()


#static func str(t: Type):
	#return Type.keys()[t]
