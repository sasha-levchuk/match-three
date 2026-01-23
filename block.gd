# TO DO: delay the matching if the piece above hasn't landed yet
class_name Block extends PhysicsBody2D
enum Type {
	BLUE,
	YELLOW,
	GREEN,
	RED,
	#PURPLE
}
var powerup: Powerup
@export var type: Type = Type.values().pick_random() as Type
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
@export var draggable: Draggable
@export var collider: CollisionShape2D
@onready var size: float = collider.shape.size.y
func _to_string(): return Type.keys()[type].left(1) + str(name) 


func _ready():
	num_blocks = ( num_blocks + 1 ) % 1000
	setup_color()
	name = str(num_blocks).pad_zeros(3)
	$Name.text = str(self)


func setup_color():
	modulate = type_colors[type]


var fall_time: float
func _physics_process(delta):
	fall_time += delta
	var collision := move_and_collide(Vector2.DOWN * 200 * fall_time)
	if not collision: 
		return
	fall_time = 0
	var body := collision.get_collider()
	if body is Block and body.state == State.FALLING: 
		return
	Matcher.match_block_fall(self)
	set_physics_process(false)
	state = State.IDLE


func delete_or_trigger():
	if state == State.IDLE: 
		if powerup:
			powerup.trigger()
		else:
			delete()


func delete():
	state = State.DELETING
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0, .1)
	tween.tween_callback(func():
		get_neighbor(Vector2i.UP, Global.collapse_requested.emit)
		queue_free()
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


func make_powerup(_type: Powerup.Type):
	if _type == Powerup.Type.NONE:
		delete()
		return
	powerup = Powerup.new(self, _type as Powerup.Type)
	sprite.frame = 1 + _type as int
	modulate = Color.WHITE
	if move_and_collide(Vector2.DOWN):
		state = State.IDLE
	else:
		state = State.FALLING
		set_physics_process(true)


func _on_button_match_pressed():
	Matcher.match_block_fall(self)


func get_neighbor(direction: Vector2i, callback := Callable()) -> Block:
	if direction==Vector2i.UP: direction *= 10
	var params := PhysicsRayQueryParameters2D.create(position, position+direction*size)
	var result := get_world_2d().direct_space_state.intersect_ray(params)
	if result.is_empty(): return null
	add_sibling($Line.duplicate().place(position, position+direction*size))
	if callback: callback.call(result.collider)
	return result.collider as Block


func get_block_at(offset: Vector2i, callback:=Callable()) -> Block:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = position + offset * size
	var result := get_world_2d().direct_space_state.intersect_point(params)
	if result.is_empty(): return null
	var node: Node = result.pop_back().collider
	if not node is Block: return null
	var block := node as Block
	if block.state != Block.State.IDLE: return null
	if block.is_queued_for_deletion(): return null
	if not is_instance_valid(block): return null
	add_sibling($Dot.duplicate().place(position+offset*size))
	if callback: callback.call(block)
	return block
