class_name Piece extends Area2D
static var counter: int
const GRAVITY := 2222
const TWEEN_TIME := .22
enum Type{
	SKULL, 
	FIRE, 
	#ICE,
	#MAGIC
	}
@onready var type: Type = Type.values().pick_random() as Type
enum State{IDLE, DRAGGED, BUSY, FALLING}
var state: State:
	set(new_state):
		state = new_state
		modulate = {State.IDLE: Color.WHITE, State.DRAGGED: Color.LIGHT_GREEN,
					State.BUSY: Color.YELLOW,State.FALLING: Color.DIM_GRAY }[state]
var landed: Signal
var moved: Signal
var departed: Signal
func _to_string(): return str(name)


func _ready():
	name = Type.keys()[type].left(1) + str(counter).pad_zeros(2)
	%NameLabel.text = str(name)
	counter += 1
	%Sprite2.frame = 1 + type as int
	area_entered.connect(func(piece_below: Piece):
		#if not is_processing() or not piece_below.is_processing(): return
		#if piece_below.position.y > position.y:
		speed = maxf( speed, piece_below.speed)
			#position.y = piece_below.position.y - 108
		)


func _input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton:
		if event.is_pressed() and state==State.IDLE:
			state = State.DRAGGED
		elif event.is_released() and state==State.DRAGGED:
			place_back()
	if event is InputEventMouseMotion and state==State.DRAGGED:
		%Sprite.position += event.relative


func _mouse_exit():
	if state==State.DRAGGED:
		var mouse := get_local_mouse_position()
		var axis := mouse.abs().max_axis_index()
		var direction := Vector2i.ZERO
		direction[axis] = sign(mouse[axis]) as int
		moved.emit(direction)


func place_back():
	state = State.BUSY
	var tween := create_tween()
	tween.tween_property(%Sprite, 'position', Vector2.ZERO, TWEEN_TIME)
	await tween.finished
	state = State.IDLE


func delete():
	prints('deleting', name)
	state = State.BUSY
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0.0, TWEEN_TIME)
	await tween.finished
	departed.emit()
	queue_free()


var target: Vector2
var speed: float
func _process(delta:float):
	speed += delta * GRAVITY
	position = position.move_toward(target, delta * speed)
	if position == target:
		speed = 0
		state = State.IDLE
		set_process(false)
		landed.emit(self)
