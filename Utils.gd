extends Node
class_name Utils


static var prev_time: float = 0.0
static func time():
	var new_time := Time.get_ticks_usec() - prev_time
	prev_time = Time.get_ticks_usec()
	return new_time
