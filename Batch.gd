class_name Batch

var counter := 0

signal finished


func add_signal(new_signal: Signal):
	if new_signal.is_connected(decrement):
		push_error(new_signal.get_object(), ' is already connected')
		breakpoint
	counter += 1
	new_signal.connect(decrement, CONNECT_ONE_SHOT)


func decrement():
	counter -= 1
	if not counter:
		finished.emit()
