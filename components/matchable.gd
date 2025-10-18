class_name Matchable

enum Type{
	BLUE, 
	YELLOW, 
	GREEN,
	#RED,
	#WHITE,
	}
var type: Type


func _init(_type: Type):
	type = _type
