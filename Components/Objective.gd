class_name Objective
extends Node
var block: Block


func _init(_block: Block):
	block = _block
	block.sprite.frame = 11
	block.matchable.queue_free()
	block.matchable = null
