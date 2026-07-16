class_name Matchable extends Tile

enum Type {
	SKULL,
	ICE,
	FIRE,
	#MAGIC,
	#PLUME,
}

var type: Type
@export var match_icon: Sprite2D
@export var match_flash: Polygon2D
@export var type_colors: Dictionary[Type, Color]


func _ready() -> void:
	super._ready()
	type = Type.values().pick_random() as Type
	match_icon.frame = 1 + type


func switch_type():
	type = ( int(type) + 1 ) % Type.size() as Type
	match_icon.frame = 1 + type


