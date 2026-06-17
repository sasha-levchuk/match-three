class_name Explosive extends Block

enum Type {
	DISCO,
	TNT,
	ROCKETV,
	ROCKETH,
	WINGS,
	NONE
}

static var scenes: Dictionary[Type, PackedScene] = {
	Type.TNT: preload('res://tnt.tscn'),
	#Type.WINGS: preload('res://wings.tscn'),
}

@export var type: Type
