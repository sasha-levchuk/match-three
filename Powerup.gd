class_name Powerup
enum Type {
	DISCOBALL, 
	TNT, 
	ROCKETV, 
	ROCKETH, 
	FAN, 
	NONE,
	}
var type: Type
var block: Block # kinda like "this" of the component


static func str(t: Type):
	return Type.keys()[t]


func _init(_block: Block, _type: Type):
	type = _type
	block = _block


func trigger():
	block.sprite.frame = 6
	block.delete()
	if type==Type.DISCOBALL:
		Global.discoball_triggered.emit(Block.Type.values().pick_random() as Block.Type)
		return
	var offsets: Array[Vector2]
	match type:
		Type.TNT:
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
		block.get_block_at(offset, func(b: Block): b.delete_or_trigger())
