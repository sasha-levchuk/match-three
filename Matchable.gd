extends Sprite2D
class_name Matchable

enum Type {
	GREEN,
	BLUE,
	ORANGE,
	PURPLE,
}
@onready var block := owner as Block
@export var type: Type = Type.values().pick_random() as Type
var frame_offset := 1


func _ready():
	frame = frame_offset + type as int
	block.name = Type.keys()[type].left(1)
	block.fell_down.connect(Matcher.match_block_fall.bind(block))
