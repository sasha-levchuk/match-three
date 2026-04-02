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
	block.sprite.frame = 10
	var offsets: Array[Vector2]
	match type:
		Type.DISCOBALL:
			var match_type := Matchable.Type.values().pick_random() as Matchable.Type
			for del_block: Block in block.get_tree().get_nodes_in_group('matchables'):
				if not del_block.matchable.type==match_type: continue
				if not del_block.state == Block.State.IDLE: continue
				del_block.delete()
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
		Game.call_block(block.posi+offset, func(b:Block): b.explode())
	return block.animate_fadeout()


static func str(t: Type):
	return Type.keys()[t]
