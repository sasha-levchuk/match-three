class_name Block extends PhysicsBody2D
static var num_blocks := 0
enum State{FALLING, IDLE, DRAGGED, BUSY}
var state: State:
	set(new_state):
		#prints(self, 'went from', State.keys()[state], State.keys()[new_state])
		state = new_state
		$StateLabel.text = state_str
var state_str: String:
	get(): return State.keys()[state]
@export var sprite: Sprite2D
@export var draggable: Draggable
@export var matchable: Matchable
@export var gravity: Gravity
@export var raycaster: Raycaster
var powerup: Powerup
@export var collider: CollisionShape2D
@onready var size: float = collider.shape.size.y
func _to_string(): return str(name)
signal match_checked(result: Matchable.Result)


func _ready():
	$StateLabel.text = state_str
	add_to_group('blocks') # used in a discoball trigger
	num_blocks = (num_blocks + 1) % 1000
	name += str(num_blocks).pad_zeros(3)
	$Name.text = str(self)


func _on_fall_down():
	if matchable:
		var result = matchable.find_matches()
		if result.is_success:
			apply_result(result)
	state = State.IDLE


func _on_swap(direction: Vector2i, neighbor: Block):
	state = State.BUSY
	add_collision_exception_with(neighbor)
	await swap(direction)
	if matchable:
		var result := matchable.find_matches(neighbor, direction)
		if result.is_success:
			await get_tree().process_frame
			match_checked.emit(result)
			apply_result(result)
		else:
			neighbor.match_checked.connect(_on_neighbor_match_checked, CONNECT_ONE_SHOT)
	else:
		await get_tree().process_frame
		match_checked.emit(Matchable.Result.new(true))


func _on_neighbor_match_checked(neighbor_result: Matchable.Result):
	if neighbor_result.is_success:
		position = sprite.global_position
		sprite.position = Vector2.ZERO
		z_index = 0
		fall()
	else:
		await reset_position()
	send_collapse_impulse_up()


func reset_position():
	var tween = create_tween()
	tween.tween_property(sprite, 'position', Vector2.ZERO, 0.1)
	await tween.finished
	z_index = 0
	fall()


func apply_result(result: Matchable.Result):
	for blck: Block in result.matches:
		blck.delete()
	if result.is_reward:
		var block := load("res://block.tscn").instantiate() as Block
		block.matchable.free()
		block.matchable = null
		block.powerup = Powerup.new(block, result.reward)
		block.global_position = sprite.global_position
		add_collision_exception_with(block)
		await get_tree().process_frame
		add_sibling(block)
		queue_free()
	else:
		delete()


func swap(direction: Vector2i)->Signal:
	state = State.BUSY
	z_index = 1
	var tween := create_tween()
	tween.tween_property(sprite, 'position', direction*size, 0.1)
	return tween.finished


func send_collapse_impulse_up():
	var neighbor := raycaster.get_neighbor(Vector2i.UP)
	if neighbor and neighbor.state==State.IDLE:
		neighbor.fall()


func fall():
	state = State.FALLING
	gravity.set_process(true)
	await get_tree().create_timer(0.05).timeout
	send_collapse_impulse_up()


func delete():
	state = State.BUSY
	$Glow.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0, .2)
	await tween.finished
	send_collapse_impulse_up()
	queue_free()
