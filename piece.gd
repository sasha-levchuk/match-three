class_name Piece extends Button
static var n_pieces: int
enum State{IDLE, SWIPING, DRAGGING, DESTROYING}
const SWIPE_SPEED := .4
const DRAG_SPEED := .2
const DELETION_TIME := .3
@export var draggable: Draggable
@export var fall_curve: Curve
@export var destroy_button: Button
@export var matchable_colors: Dictionary[Matchable.Type, Color]
@export var powerup_colors: Dictionary[Powerup.Type, Color]
var state: State
var id: String
var matchable: Matchable
var powerup: Powerup
var coord: Vector2i
var move_tween: Tween
var destination: Vector2i
var height: int
signal drag_started
signal drag_finished
signal drag_reverted
signal destroyed
signal swiped


func init(_coord: Vector2i):
	coord = _coord
	destination = coord
	n_pieces += 1
	id = str(n_pieces).pad_zeros(2)
	update_name()
	position = to_world(coord)


func update_name():
	name = id + str(coord.x) + str(coord.y)
	text = name


func init_matchable(type: Matchable.Type):
	matchable = Matchable.new(self, type)
	dragged.connect(matchable.on_dragged)
	swiped.connect(matchable.on_swiped)
	self_modulate = matchable_colors[type]
	id = Matchable.Type.keys()[type].left(1)


func init_powerup(type: Powerup.Type):
	powerup = Powerup.new(self, type as Powerup.Type)
	dragged.connect(powerup.on_dragged)
	self_modulate = powerup_colors[type]
	id = Powerup.Type.keys()[type].left(3)


func can_swipe():
	return state==State.SWIPING or state==State.IDLE


func swipe(_height: int):
	height += _height
	state = State.SWIPING
	destination.y -= _height
	if destination.y < 0: push_error('tried moving ', self, ' to ', destination)
	var time := position.distance_to(to_world(destination))/size.y * SWIPE_SPEED
	time = sqrt(time*10) / 10
	move(destination, time)


func drag(where := destination):
	destination = where
	state = State.DRAGGING
	move(where)


func move(where_to: Vector2i, time: float = DRAG_SPEED) -> Tween:
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
		name = id + str(coord.x) + str(coord.y)
		text = name
		height = 0
	)
	return move_tween


func destroy():
	if state==State.DESTROYING: return
	if powerup: powerup.trigger()
	state = State.DESTROYING
	if move_tween: move_tween.kill()
	disabled = true
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0.0, DELETION_TIME)
	tween.tween_callback(func():
		queue_free()
		var where_from := coord
		coord = -Vector2i.ONE
		destination = -Vector2i.ONE
		destroyed.emit(self, where_from)
	)


func to_world(v: Vector2i) -> Vector2:
	return Vector2(v) * size * Vector2(1,-1) - Vector2(0, size.y)


func _to_string(): return str(name)


func flash():
	modulate = Color(3,3,-3)
	create_tween().tween_property(self, 'modulate', Color.WHITE, .5)
