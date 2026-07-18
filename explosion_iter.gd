class_name ExplosionIter

static var tiles: Dictionary[Vector2i, Tile]
var origin: Vector2i
var branches: int
var length: int
var width: int

var offset: Vector2i
var counter: int


func _init(
	_origin: Vector2i, 
	_branches := 4,
	_length := 9,
	axis := 0,
	_width := 1
) -> void:
	origin = _origin
	branches = _branches
	length = _length
	width = _width
	offset = Vector2i.DOWN if axis%2 else Vector2i.RIGHT


func get_next_tile(iter: Array) -> bool:
	while branches:
		counter += 1
		var tile := tiles.get(origin+offset*counter) as Tile
		if counter <= length and tile and tile.is_idle:
			iter[0] = tile
			return true
		else:
			branches -= 1
			offset = -offset if branches%2 else Vector2i(-offset.y, offset.x)
			counter = 0
	return false


func _iter_init(iter: Array) -> bool:
	return get_next_tile(iter)


func _iter_next(iter: Array) -> bool:
	return get_next_tile(iter)


func _iter_get(iter: Variant) -> Variant:
	return iter

