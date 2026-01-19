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


func _init(_block: Block, _type: Type):
	type = _type
	block = _block


func trigger():
	block.sprite.frame = 6
	block.delete()
	var offsets: Array[Vector2]
	match type:
		Type.DISCOBALL:
			for x in 20:
				for y in 20:
					offsets.append(Vector2(x-10, y-10))
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

	var random_type := Block.Type.values().pick_random() as Block.Type
	for offset: Vector2 in offsets:
		var block2 := Global.get_block(block.position + offset*block.size)
		if block2: # might optimize this later on
			if type==Type.DISCOBALL:
				if block2.type == random_type and not block2.powerup:
					block2.delete()
			else:
				block2.delete_or_trigger()
