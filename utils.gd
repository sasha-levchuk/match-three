class_name Utils


static func soft_assert(condition: Variant, ...args: Array):
	if not not condition: return
	var msg := String()
	for arg in args:
		msg += str(arg) + ' '
	push_error("Assertion failed: %s" % msg)
	Engine.time_scale = 0.0
	Global.get_tree().paused = true   
	#EngineDebugger.debug()
