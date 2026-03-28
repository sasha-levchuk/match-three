class_name Objective
var block: Block


func _init(_block: Block):
	block = _block
	block.sprite.frame = 11
	block.matchable.queue_free()
	block.matchable = null


func collect():
	block.z_index = 88
	Game.test_signal.emit(block.sprite)
	await block.get_tree().create_timer(2).timeout
	#var tween := create_tween()
	#tween.set_parallel(true)
	#tween.tween_property(block.sprite, 'global_position', Vector2(170,64), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	#tween.tween_property(block.sprite, 'scale', Vector2(0.5, 0.5), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	#await tween.finished
	Game.score_incremented.emit()
