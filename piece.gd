class_name Piece extends Button
static var n_pieces: int
const SWIPE_SPEED := .4
const DRAG_SPEED := .2
const DELETION_TIME := .3
var id: String
var matchable: Matchable
var powerup: Powerup
var coord: Vector2i
var move_tween: Tween
enum State{IDLE, SWIPING, DRAGGING, DELETED}
var state: State
var destination: Vector2i
@export var draggable: Draggable
@export var db: Resource
@export var fall_curve: Curve


func init(_coord: Vector2i, component: Variant, type: int):
	coord = _coord
	destination = coord
	match component:
		Matchable:
			matchable = Matchable.new(self, type as Matchable.Type)
			self_modulate = db.matchable_type_colors[type]
			id = Matchable.Type.keys()[type].left(1)
		Powerup:
			powerup = Powerup.new(self, type as Powerup.Type)
			self_modulate = db.powerup_type_colors[type]
			id = Powerup.Type.keys()[type].left(1)
	n_pieces += 1
	id += str(n_pieces).pad_zeros(2)
	name = id + str(coord.x) + str(coord.y)
	text = name
	position = to_world(coord)


func swipe(offset: int):
	state = State.SWIPING
	destination.y -= offset
	if destination.y < 0: push_error('tried moving ', self, ' to ', destination)
	var time := position.distance_to(to_world(destination))/size.y * SWIPE_SPEED
	time = sqrt(time*10) / 10
	_move(destination, time)


func drag(where: Vector2i):
	state = State.DRAGGING
	_move(where, DRAG_SPEED)


func _move( where_to: Vector2i, time: float ) -> void:
	disabled = true
	z_index += 1
	if move_tween: move_tween.kill()
	move_tween = create_tween()
	move_tween.tween_property(self, 'position', to_world(where_to), time).set_custom_interpolator(fall_curve.sample_baked)
	move_tween.tween_callback(func():
		z_index -= 1
		disabled = false
		state = State.IDLE
		coord = where_to
		destination = where_to
		name = id + str(coord.x) + str(coord.y)
		text = name
		Event.piece_arrived.emit(self)
	)


func delete():
	state = State.DELETED
	if move_tween: move_tween.kill()
	disabled = true
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0.0, DELETION_TIME)
	tween.tween_callback(func():
		queue_free()
		Event.piece_deleted.emit(self)
	)


func to_world(v: Vector2i) -> Vector2:
	return Vector2(v) * size * Vector2(1,-1) - Vector2(0, size.y)


func _to_string(): return str(name)


func flash():
	modulate = Color(3,3,-3)
	create_tween().tween_property(self, 'modulate', Color.WHITE, .5)
