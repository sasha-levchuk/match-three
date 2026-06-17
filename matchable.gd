@tool
class_name Matchable extends Block

enum Type {
	SKULL,
	ICE,
	FIRE,
	MAGIC,
	PLUME,
}

var type: Type
@export var type_colors: Dictionary[Type, Color]


func _ready() -> void:
	type = Type.values().pick_random() as Type
	name = Type.keys()[type].left(1) + str(count)
	sprite.modulate = type_colors[type]
	%Label.text = name


func _to_string() -> String:
	return str(name)


func _on_id_set(v):
	name = "SpawnPoint_%d" % v

