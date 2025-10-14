class_name Piece extends Button

const MOVE_SPEED := .4
const DELETION_TIME := .9
enum Type {BLUE, YELLOW, GREEN, RED}
@export var type: Type
@export var TypeColor: Dictionary[Type, Color]
var coord: Vector2i
var move_tween: Tween
var id: int
enum State{IDLE, MOVING, DRAGGING, DELETED}
var state: State
var destination: Vector2i:
	set(new_dest):
		destination = new_dest
		if new_dest!=coord:
			print(self, 'move to', new_dest)
			move(new_dest)


func _ready():
	set_process(false)


func flash(col := Color.RED):
	%Overlay.modulate = col
	create_tween().tween_property(%Overlay, 'modulate:a', 0, MOVE_SPEED)


func move(where_to) -> void:
	if state==State.DELETED: return
	state = State.MOVING
	if where_to.y < 0:
		push_error('tried moving ', self, ' to ', where_to)
	disabled = true
	if move_tween: move_tween.kill()
	move_tween = create_tween()
	var time := position.distance_to(to_world(where_to)) / size.y * MOVE_SPEED + MOVE_SPEED*2
	#prints(self, 'will move from', position, 'to', to_world(where_to), 'over', time, 'sec')
	move_tween.tween_property(self, 'position', to_world(where_to), time)
	move_tween.tween_callback(func():
		disabled = false
		state = State.IDLE
		coord = where_to
		update_name()
		Event.piece_arrived.emit(self)
	)


func delete():
	state = State.DELETED
	move_tween.kill()
	disabled = true
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0.0, DELETION_TIME)
	tween.tween_callback(func():
		prints('freeing', self)
		queue_free()
		Event.piece_deleted.emit(coord)
	)


func _to_string():
	return text


func update_name():
	text = Type.keys()[type][0]+str(id).pad_zeros(2)+'-'+str(coord.x)+str(coord.y)


func to_world(v: Vector2i) -> Vector2:
	return Vector2(v) * size * Vector2(1,-1) - Vector2(0, size.y)


var drag_center: Vector2
var drag_offset: Vector2
func _on_button_down():
	drag_center = global_position + size/2
	drag_offset = get_local_mouse_position()
	set_process(true)
	state = State.DRAGGING


func _process(_delta):
	var mouse := get_global_mouse_position()
	global_position = mouse - drag_offset
	var offset: Vector2i = ((mouse-drag_center)/size*Vector2(2,-2)).limit_length(sqrt(2))
	if offset and not offset.x * offset.y:
		set_process(false)
		prints(self, 'emits the dragged signal towards', offset)
		Event.piece_dragged.emit(self, coord + offset)


func _on_button_up():
	if state==State.DRAGGING:
		set_process(false)
		move(coord)
