class_name Block extends PhysicsBody2D
enum Type {
	BLUE,
	YELLOW,
	GREEN,
	RED,
	#PURPLE
}
enum PowerupType {DISCOBALL, TNT, ROCKETV, ROCKETH, FAN}
var powerup_type: PowerupType
var is_powerup: bool
var type: Type = Type.values().pick_random() as Type
@export var type_colors: Dictionary[Type, Color]
static var num_blocks := 0
enum State{ FALLING, HELD, MOVING, MATCHING, RETURNING, DELETING, IDLE }
@onready var state: State:
	set( new_state):
		state = new_state
		$StateLabel.text = state_str
var state_str: String: 
	get(): return Block.State.keys()[state]
var pos_simple: Vector2i: 
	get(): return position / size as Vector2i
@export var sprite: Sprite2D
@export var collider: CollisionShape2D
@export var draggable: Draggable
@onready var size: Vector2 = collider.shape.size
func _to_string(): return Type.keys()[type].left(1) + str(name) 


func _ready():
	num_blocks = ( num_blocks + 1 ) % 1000
	modulate = type_colors[type]
	name = str(num_blocks).pad_zeros(3)
	$Name.text = str(self)
	fall()


func fall():
	state = State.FALLING
	set_physics_process(true)


var fall_time: float
func _physics_process(delta):
	fall_time += delta
	var collision := move_and_collide(Vector2.DOWN * 80 * fall_time)
	if collision:
		fall_time = 0
		var body := collision.get_collider()
		var block := body as Block if body is Block else null
		var is_floor := not block
		if is_floor or block.state != State.FALLING:
			set_physics_process(false)
			state = State.IDLE
			Event.block_landed.emit(self)


func delete():
	state = State.DELETING
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0, 0.1)
	tween.tween_callback(func():
		queue_free()
		Event.block_deleted.emit(position)
	)


func move(to: Vector2):
	state = State.MOVING
	var tween := create_tween()
	tween.tween_property(sprite, 'global_position', to, 0.1)
	tween.tween_callback(func():
		z_index = 0
		position = to
		sprite.position = Vector2.ZERO
	)
	return tween.finished


func check_and_fall():
	if not move_and_collide(Vector2.DOWN):
		fall()
		await get_tree().create_timer(0.05).timeout
		Event.collapse_initiated.emit(position)
	else:
		state = State.IDLE


func make_powerup(_type: Matcher.Type):
	is_powerup = true
	sprite.frame = 1 + _type as int
	modulate = Color.WHITE
	powerup_type = _type as PowerupType
