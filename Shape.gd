class_name Shape
var type: Matcher.Type
var directions: int
var size: int
var handler: Callable


func _init(_type: Matcher.Type, _directions: int, _size: int, _handler: Callable):
	type = _type
	directions = _directions
	size = _size
	handler = _handler
