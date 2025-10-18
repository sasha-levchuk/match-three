class_name Powerup
enum Type {DISCOBALL, TNT, ROCKET, FAN, NONE}
var type: Type


func _init(_type: Type):
	type = _type
