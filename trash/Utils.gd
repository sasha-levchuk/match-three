extends Node
class_name Utils
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]


static var prev_time: float = 0.0
static func time():
	var new_time := Time.get_ticks_usec() - prev_time
	prev_time = Time.get_ticks_usec()
	return new_time


static func await2(signal1: Signal, signal2: Signal):
	var done := Signal()
	var counter := {times = 0}
	var callback := func():
		counter.times += 1
		if counter.times==2:
			done.emit()
	signal1.connect(callback, CONNECT_ONE_SHOT)
	signal2.connect(callback, CONNECT_ONE_SHOT)
	await done


static func v2i_rotated(main_vec:Vector2i, rotate_to: Vector2i) -> Vector2i:
	return Vector2i(-main_vec.y, main_vec.x)*rotate_to.x + main_vec*rotate_to.y
