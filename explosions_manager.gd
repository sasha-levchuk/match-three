class_name ExplosionsManager

var slots: Dictionary[Vector2i, Slot]


func _init(_slots) -> void:
	slots = _slots


func handle(_move: Move):
	#if move.slot1.piece is Rune or move.slot2.piece is Rune:
		#move.is_successful = false
	pass


func handle_single(type: Explosive.Type, coord: Vector2i):
	type_handlers[type].call(coord)


var type_handlers: Dictionary[Explosive.Type, Callable] = {
	Explosive.Type.TNT: _handle_tnt,
}


func _handle_tnt(coord: Vector2i):
	for hit_coord: Vector2i in _coords_square(coord, 1):
		if hit_coord in slots:
			slots[hit_coord].get_hit()


func _coords_square(coord: Vector2i, radius: int) -> Array[Vector2i]:
	var coords: Array[Vector2i]
	for x: int in range(-radius, radius+1):
		for y: int in range(-radius, radius+1):
			coords.append(coord+Vector2i(x,y))
	coords.erase(coord)
	return coords
