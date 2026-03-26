class_name Block extends PhysicsBody2D
static var num_blocks := 0
enum State{FALLING, IDLE, DRAGGED, BUSY, DELETING, TRANSFORMING}
var state: State:
	set(new_state):
		state = new_state
		$StateLabel.text = state_str
		set_process(state == State.IDLE)
var state_str: String:
	get(): return State.keys()[state]
@export var sprite: Sprite2D
@export var draggable: Draggable
@export var matchable: Matchable
@export var gravity: Gravity
@export var raycaster: Raycaster
var powerup: Powerup
@export var collider: CollisionShape2D
@onready var size: float = collider.shape.size.y * scale.y
func _to_string(): return str(name)
signal match_checked(result: Matchable.Result)


func _ready():
	$StateLabel.text = state_str
	add_to_group('blocks') # used in a discoball trigger
	num_blocks = (num_blocks + 1) % 1000
	name += str(num_blocks).pad_zeros(3)
	$Name.text = str(self)


var idle_timer := 0.0
func _process(delta:float):
	idle_timer += delta
	if idle_timer > 5.0:
		gravity.fall()
		idle_timer = 0.0


func _on_fall_down():
	if matchable:
		var result = matchable.find_matches()
		if result.is_success:
			apply_result(result)
		else:
			state = State.IDLE
	else:
		state = State.IDLE


func _on_swap(direction: Vector2i, coordinator: Draggable.Coordinator):
	state = State.BUSY
	await move(position+direction*size, coordinator)
	var result := Matchable.Result.new(true)
	if powerup: powerup.trigger()
	if matchable: result = matchable.find_matches(direction)
	var neighbor_success := await coordinator.combine_result(result.is_success)
	if result.is_success:
		apply_result(result)
	else:
		z_index = 0
		if not neighbor_success:
			await move(position-direction*size, coordinator)
		gravity.fall(0.1)


func move(new_pos: Vector2, coordinator: Draggable.Coordinator):
	add_collision_exception_with(coordinator.neighbors[self])
	var tween := create_tween()
	tween.tween_property(sprite, 'global_position', new_pos, 0.15)
	await tween.finished
	position = new_pos
	sprite.position = Vector2.ZERO
	remove_collision_exception_with(coordinator.neighbors[self])


func reset_position():
	var tween = create_tween()
	tween.tween_property(sprite, 'position', Vector2.ZERO, 0.2)
	await tween.finished
	z_index = 0
	#await get_tree().create_timer(0.1).timeout
	gravity.fall()


func apply_result(result: Matchable.Result):
	for blck: Block in result.matches:
		blck.delete()
	if result.is_reward:
		make_powerup(result.reward)
	else:
		delete()


func make_powerup(type: Powerup.Type):
	Game.score_incremented.emit()
	var block := load("res://block.tscn").instantiate() as Block
	block.scale = Spawner.instance.block_scale * Vector2.ONE
	block.matchable.free()
	block.matchable = null
	block.powerup = Powerup.new(block, type)
	add_collision_exception_with(block)
	await get_tree().process_frame
	await get_tree().process_frame
	block.position = position
	add_sibling(block)
	state = State.TRANSFORMING
	queue_free()
	block.gravity.fall(0.3)


func send_collapse_impulse_up():
	var neighbor := raycaster.get_neighbor(Vector2i.UP)
	if neighbor and neighbor.state==State.IDLE:
		neighbor.gravity.fall(0.05)


func delete():
	Game.score_incremented.emit()
	state = State.DELETING
	$Glow.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0, .2)
	await tween.finished
	send_collapse_impulse_up()
	Spawner.respawn( int(position.x/size) )
	queue_free()
