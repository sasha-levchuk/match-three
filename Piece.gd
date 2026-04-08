class_name Piece extends Area2D
static var counter: int
const GRAVITY := 5555
const TWEEN_TIME := .1 # seconds
var is_matchable := true
enum Type{
	SKULL,
	FIRE,
	ICE,
	MAGIC,
	}
var is_powerup := false
enum PowerupType{DISCOBALL, TNT, ROCKETV, ROCKETH, FAN}
var powerup_type: PowerupType
@onready var type: Type = Type.values().pick_random() as Type
enum State{FALLING, IDLE, DRAGGED, BUSY}
var state: State:
	set(new_state):
		state = new_state
		modulate = {
			State.IDLE: Color.WHITE,
			State.DRAGGED: Color.FUCHSIA,
			State.BUSY: Color.ORANGE,
			State.FALLING: Color.CADET_BLUE,
		}[state]
var landed: Signal
var moved: Signal
var departed: Signal
func _to_string(): return str(name)


func _ready():
	name = Type.keys()[type].left(1) + str(counter).pad_zeros(2)
	%NameLabel.text = str(name)
	counter += 1
	%Sprite2.frame = 1 + type as int
	area_entered.connect(func(piece: Piece):
		if not is_physics_processing() or not piece.is_physics_processing(): 
			return
		if piece.position.y < position.y: # entering piece is above this one
			speed = piece.speed
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
	state = State.BUSY
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0.0, TWEEN_TIME)
	await tween.finished
	queue_free()
	departed.emit()


func make_powerup(_powerup_type: PowerupType):
	is_matchable = false
	is_powerup = true
	powerup_type = _powerup_type
	%Sprite2.queue_free()
	%Sprite.frame = 5 + powerup_type as int
	state = State.IDLE


func move(new_position: Vector2) -> Signal:
	state = State.BUSY
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, 'position', new_position, TWEEN_TIME)
	tween.tween_property(%Sprite, 'position', Vector2.ZERO, TWEEN_TIME)
	return tween.finished


var target: Vector2
var speed: float
func _physics_process(delta:float):
	speed += delta * GRAVITY
	position = position.move_toward(target, delta * speed)
	if position == target:
		speed = 0
		set_physics_process(false)
		if is_matchable:
			landed.emit(self)
		elif is_powerup:
			state = State.IDLE
