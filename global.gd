extends Node
var get_idle_block: Callable
signal swap_requested
signal collapse_requested
signal collapse_button_pressed
signal discoball_triggered


func pause(time: float):
	get_tree().paused = true
	get_tree().create_timer(time).timeout.connect(func():
		get_tree().paused = false)
