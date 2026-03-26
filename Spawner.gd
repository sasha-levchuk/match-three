class_name Spawner
extends Node2D
static var instance: Spawner
static var queue: Array[int]
static var cooldown: Array[float]
const N_COLUMNS := 7


func _ready():
	instance = self
	queue.resize(N_COLUMNS)
	queue.fill(N_COLUMNS)
	cooldown.resize(N_COLUMNS)
	cooldown.fill(0.0)


func _process(delta: float):
	var misfires := 0
	for col: int in N_COLUMNS:
		if cooldown[col] > 0.0:
			cooldown[col] -= delta
		elif queue[col]:
			var point := Vector2(position.x + col*150, position.y)
			if is_free(point):
				instance.make_block(col)
				queue[col] -= 1
			cooldown[col] = .25
		elif cooldown[col]:
			cooldown[col] = 0.0
		else:
			misfires += 1
	if misfires==N_COLUMNS:
		set_process(false)


func is_free(point: Vector2)->bool:
	var params := PhysicsRayQueryParameters2D.create(point, point+Vector2.DOWN*75)
	params.hit_from_inside = true
	var result := get_world_2d().direct_space_state.intersect_ray(params)
	return result.is_empty()


static func respawn(col: int):
	queue[col] += 1
	instance.set_process(true)


func make_block(col: int):
	var block := load("res://block.tscn").instantiate() as Block
	block.matchable.type = Matchable.Type.values().pick_random() as Matchable.Type
	block.position = Vector2(position.x + col*150, position.y)
	add_sibling(block)
