extends Node
var score := 0
signal tnt_exploded
signal score_incremented
signal test_signal


func _ready():
	score_incremented.connect(func():score += 1)


func make_powerup(type: Powerup.Type, pos: Vector2) -> Block:
	var block := load("res://block.tscn").instantiate() as Block
	block.scale = Spawner.instance.block_scale * Vector2.ONE
	block.powerup = Powerup.new(block, type)
	block.position = pos
	get_tree().create_timer(0.05).timeout.connect(add_sibling.bind(block))
	return block
