extends Node

@warning_ignore("unused_signal")
signal piece_deleted
@warning_ignore("unused_signal")
signal piece_arrived
@warning_ignore("unused_signal")
signal piece_dragged
@warning_ignore("unused_signal")
signal match_processed


#var events: Dictionary[Signal, Array]
#func register(event: Signal, callback: Callable):
	#events.get_or_add(event, []).append(callback)
	#event.connect(callback)
#
#
#func unregister(event: Signal, callback := Callable()):
	#var callbacks: Array = events.get(event)
	#if not callbacks: return
	#if callback:
		#if callbacks.has(callback):
			#event.disconnect(callback)
	#else:
		#while callbacks:
			#event.disconnect(callbacks.pop_back())
