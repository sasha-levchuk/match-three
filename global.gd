extends Node
var get_idle_block: Callable



func pause(time: float):
	get_tree().paused = true
	get_tree().create_timer(time).timeout.connect(func():
		get_tree().paused = false)
