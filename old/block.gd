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
var powerup: Powerup
var objective: Objective
@export var collider: CollisionShape2D
@onready var size: float = 108.0 #collider.shape.size.y
var posi: Vector2i:
	get():
		return Vector2i(position/size)
func _to_string(): return str(name)
signal match_checked(result: Matchable.Result)


func _ready():
	$StateLabel.text = state_str
	add_to_group('blocks') # used in a discoball trigger
	num_blocks = (num_blocks + 1) % 1000
	name += str(num_blocks).pad_zeros(3)
	$Name.text = str(self)
	if powerup:
		gravity.fall(0.3)


var idle_timer := 0.0
func _process(delta:float):
	idle_timer += delta
	if idle_timer > 5.0:
		gravity.fall()
		idle_timer = 0.0


func _on_swap(direction: Vector2i, coordinator: Draggable.Coordinator):
	state = State.BUSY
	await move(posi+direction, coordinator)
	var result := Matchable.Result.new(false)
	if powerup:
		result = Matchable.Result.new(true)
		powerup.trigger()
	if matchable: result = matchable.find_matches(direction)
	var neighbor_success := await coordinator.combine_results(result.is_success)
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


func apply_result(result: Matchable.Result):
	for blck: Block in result.matches:
		blck.delete()
	if result.is_reward:
		state = State.TRANSFORMING
		add_collision_exception_with(Game.make_powerup(result.reward, position))
		queue_free()
	else:
		delete()


func collapse_upward():
	Game.call_block(posi+Vector2i.UP, func(bl:Block):
		bl.gravity.fall(0.05)
	)


func animate_fadeout():
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0, .5)
	return tween.finished


func delete():
	state = State.DELETING
	collider.set_deferred('disabled', true)
	if objective:
		await Game.animate_projectile(sprite)
	elif matchable:
		$Glow.show()
		await animate_fadeout()
	elif powerup:
		await powerup.trigger()
	collapse_upward()
	Spawner.respawn(posi.x)
	queue_free()
