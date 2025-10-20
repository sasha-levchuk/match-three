class_name Powerup
static var get_piece := Callable()
enum Type {DISCOBALL, TNT, ROCKET_V, ROCKET_H, FAN, NONE}
var type: Type
var trigger_single_behavior: Callable
var owner: Piece



func _init(_owner: Piece, _type: Type):
	type = _type
	trigger_single_behavior = {
		Type.DISCOBALL: func(): pass,
		Type.TNT: func():
			for x in range(-2,3):
				for y in range(-2,3):
					delete_piece(get_piece.call(owner.coord+Vector2i(x,y))),
		Type.ROCKET_V: func():
			range(-10,10).map(func(e):delete_piece(get_piece.call(owner.coord+Vector2i(0,e)))),
		Type.ROCKET_H: func():
			range(-10,10).map(func(e):delete_piece(get_piece.call(owner.coord+Vector2i(e,0)))),
		Type.FAN: func():
			var offset := Vector2i(1,0)
			for i in 4:
				offset = Vector2i(Vector2(offset).orthogonal())
				delete_piece(get_piece.call(owner.coord+offset)),
		}[type]
	owner = _owner
	owner.button_up.connect(trigger)


func delete_piece(piece: Piece):
	if piece and piece.state==Piece.State.IDLE:
		if piece.powerup:
			piece.powerup.trigger()
		else:
			piece.delete()


func trigger():
	owner.delete()
	trigger_single_behavior.call()
	Event.powerup_triggered.emit(owner)


func get_coords() -> Array:
	return [[0,1],[1,0],[-1,0],[0,-1]].map(func(a): return Vector2i(a[0],a[1]))
