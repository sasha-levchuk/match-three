class_name Powerup
enum Type {DISCOBALL, TNT, ROCKETV, ROCKETH, FAN}
var type: Type
var block: Block


func _init(_block: Block, _type: Type):
	type = _type
	block = _block


func trigger(get_block: Callable, get_all_blocks: Callable):
	var blocks: Array[Block]
	match type:
		Type.DISCOBALL:
			var block_type := Block.Type.values().pick_random() as Block.Type
			for queried_block: Block in get_all_blocks.call():
				if queried_block.type == block_type:
					blocks.append(queried_block)
	return blocks
