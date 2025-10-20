class_name Matchable

enum Type{
	BLUE, 
	YELLOW, 
	GREEN,
	#RED,
	#WHITE,
	}
var type: Type
var owner: Piece
signal dragged


func _init(_owner: Node, _type: Type):
	owner = _owner
	type = _type
	owner.draggable.dragged.connect(on_draggable_dragged)


func on_draggable_dragged():
	dragged.emit(owner)
