class_name Piece extends Area2D
static var counter: int
const GRAVITY := 5555
const TWEEN_TIME := .1 # seconds
var is_matchable := true
var is_powerup := false
enum Type{
	SKULL,
	ICE,
	FIRE,
	#MAGIC,
	}
@onready var type: Type = Type.values().pick_random() as Type
enum PowerupType{
	DISCOBALL, 
	TNT, 
	ROCKETV, 
	ROCKETH, 
	POOFY,
	}
var powerup_type: PowerupType
enum State{FALLING, IDLE, DRAGGED, BUSY}
var state: State
#modulate = {State.IDLE: Color.WHITE,State.DRAGGED: Color.FUCHSIA,State.BUSY: Color.ORANGE,State.FALLING: Color.CADET_BLUE}[state]
var landed: Signal
var moved: Signal
var departed: Signal
var triggered: Signal
func _to_string(): return str(name)


func _ready():
	add_to_group('matchables')
	counter += 1
	name = Type.keys()[type].left(1) + str(counter).pad_zeros(2)
	%NameLabel.text = str(name)
	%Sprite2.frame = 1 + type as int
	%BtnPowerup.pressed.connect(make_powerup.bind(PowerupType.POOFY))
	%BtnDelete.pressed.connect(delete)
	area_entered.connect(func(piece: Piece):
		if state==State.FALLING and piece.position.y < position.y:
			speed = piece.speed
		)


func _input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			%Menu.show()
		elif event.is_pressed() and state==State.IDLE:
			state = State.DRAGGED
			z_index = 1
			%Sprite.scale = Vector2.ONE * 0.53
		elif event.is_released() and state==State.DRAGGED:
			if is_powerup:
				explode()
			elif is_matchable:
				move()
	if event is InputEventMouseMotion and state==State.DRAGGED:
		%Sprite.position += event.relative


func _mouse_exit():
	if not state==State.DRAGGED: return
	var mouse := get_local_mouse_position()
	var axis := mouse.abs().max_axis_index()
	var direction := Vector2i.ZERO
	direction[axis] = sign(mouse[axis]) as int
	move()
	moved.emit(direction)


func make_powerup(_powerup_type: PowerupType):
	remove_from_group('matchables')
	is_matchable = false
	is_powerup = true
	powerup_type = _powerup_type
	%Sprite2.queue_free()
	%Sprite.frame = 5 + powerup_type as int
	await get_tree().process_frame
	state = State.IDLE


func move(where:=position) -> Signal:
	state = State.BUSY
	var tween := create_tween().set_parallel()
	tween.tween_property(%Sprite, 'position', Vector2.ZERO, TWEEN_TIME)
	tween.tween_property(%Sprite, 'scale', Vector2.ONE * .5, TWEEN_TIME)
	tween.tween_property(self, 'position', where, TWEEN_TIME)
	tween.tween_callback(func():
		z_index = 0
		state = State.IDLE
	)
	return tween.finished


func delete():
	state = State.BUSY
	var tween := create_tween().set_parallel()
	tween.tween_property(self, 'modulate:a', 0.0, TWEEN_TIME)
	tween.tween_property(self, 'modulate:a', 0.0, TWEEN_TIME)
	await tween.finished
	queue_free()
	departed.emit()


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


func delete_type(_type: Type):
	if type == _type and state == State.IDLE:
		delete()


func explode():
	state = State.BUSY
	if is_powerup:
		triggered.emit(powerup_type)
	else:
		%Sprite2.queue_free()
	%Sprite.frame = 10
	await get_tree().create_timer(0.2).timeout
	delete()
