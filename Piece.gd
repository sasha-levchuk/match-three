class_name Piece extends Area2D
static var counter: int
const GRAVITY := 6666
const TWEEN_TIME := .1 # seconds
@export var is_matchable := true
@export var is_powerup := false
@export var is_objective := false
enum Type{
	SKULL,
	ICE,
	FIRE,
	MAGIC,
	WIND,
	}
@export var type: Type
enum PowerupType{
	DISCOBALL, 
	TNT, 
	ROCKETV, 
	ROCKETH, 
	POOFY,
	}
@export var powerup_type: PowerupType
enum State{IDLE, DRAGGED, BUSY, FALLING}
var state: State
var is_idle: bool:
	get(): return state == State.IDLE
	#set(v):
		#state = v
		#modulate = {State.IDLE: Color.WHITE,State.DRAGGED: Color.FUCHSIA,State.BUSY: Color.ORANGE,State.FALLING: Color.CADET_BLUE}[state]
var landed: Signal
var moved: Signal
var departed: Signal
var triggered: Signal
func _to_string(): return str(name)


func _ready():
	set_physics_process(false)
	type = Type.values()[randi()%Game.difficulty] as Type
	counter += 1
	name = Type.keys()[type].left(1) 
	if is_powerup:
		name = PowerupType.keys()[powerup_type].left(1) 
	if is_objective:
		add_to_group(Group.OBJECTIVES)
		name = 'O'
	name += str(counter).pad_zeros(2)
	%NameLabel.text = str(name)
	%Sprite2.frame = 1 + type as int
	%BtnPoofy.pressed.connect(make_powerup.bind(PowerupType.POOFY))
	%BtnDisco.pressed.connect(make_powerup.bind(PowerupType.DISCOBALL))
	%BtnDelete.pressed.connect(delete)
	area_entered.connect(func(piece: Piece):
		if state==State.FALLING and piece.position.y < position.y:
			speed = piece.speed
		)


func _input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			%Menu.show()
		elif event.is_pressed() and is_idle:
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
	remove_from_group(Group.MATCHABLES)
	is_matchable = false
	is_powerup = true
	powerup_type = _powerup_type
	%Sprite2.queue_free()
	%Sprite.frame = 6 + powerup_type as int
	await get_tree().process_frame
	state = State.IDLE


func make_powerup_and_explode(_powerup_type: PowerupType):
	delete(5).tween_callback(triggered.emit.bind(_powerup_type))
	%Sprite.frame = 6 + _powerup_type as int
	%Sprite2.queue_free()


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


func delete(blink_times:=0) -> Tween:
	state = State.BUSY
	var tween := create_tween()
	for i in blink_times:
		tween.tween_property(%Glow, 'color', Color.ORANGE, TWEEN_TIME)
		tween.parallel().tween_property(self, 'scale', Vector2.ONE * 1.1, TWEEN_TIME)
		tween.tween_property(%Glow, 'color', Color.BLACK, TWEEN_TIME)
		tween.parallel().tween_property(self, 'scale', Vector2.ONE, TWEEN_TIME)
	tween.tween_property(%Glow, 'color', Color.ORANGE, TWEEN_TIME)
	tween.parallel().tween_property(self, 'scale', Vector2.ONE * 1.1, TWEEN_TIME)
	tween.tween_property(self, 'modulate:a', 0.0, TWEEN_TIME)
	tween.tween_callback(queue_free)
	tween.tween_callback(departed.emit)
	return tween


func delete_type(_type: Type):
	if type == _type and is_idle:
		delete(5)


func explode():
	state = State.BUSY
	if is_objective:
		Game.crystals -= 1
		Event.score_updated.emit()
	%Sprite.frame = 12 # explosion
	if is_powerup:
		await get_tree().create_timer(0.05).timeout
		triggered.emit(powerup_type)
	else:
		%Sprite2.queue_free()
	await get_tree().create_timer(0.2).timeout
	delete()


func fall(_target: Vector2):
	target = _target
	state = State.FALLING
	set_physics_process(true)


var target: Vector2
var speed: float
func _physics_process(delta:float):
	speed += delta * GRAVITY
	position = position.move_toward(target, delta * speed)
	if position == target:
		speed = 0
		set_physics_process(false)
		state = State.IDLE
		if is_matchable:
			landed.emit(self)
