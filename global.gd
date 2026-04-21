extends Node
var difficulty := 5
var objectives := 54:
	set(v):
		objectives = v
		objectives_updated.emit(v)
signal objectives_updated
