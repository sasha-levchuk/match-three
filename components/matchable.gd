class_name Matchable

enum Type{
	BLUE, 
	YELLOW, 
	GREEN,
	#RED,
	#WHITE,
	}
var type: Type

signal dragged


func _init(owner: Node, _type: Type):
	type = _type


func on_dragged():
	emit_signal()
