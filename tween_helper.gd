extends Node
const TWEEN_TIME := .1
enum Anim {
	DELETE,
	RESET
}

var anim_type_properties: Dictionary [Anim, Dictionary] = {
	Anim.RESET: {
		'scale': Vector2.ONE,
		'z_index': 0,
		'offset': Vector2.ZERO,
	}
}


func animate(type: Anim) -> Tween:
	var tw := create_tween().parallel()
	for properties_dict: Dictionary in anim_type_properties[type]:
		for property: NodePath in properties_dict:
			var value = properties_dict[property]
			tw.tween_property(self, property, value, TWEEN_TIME)
	return tw


