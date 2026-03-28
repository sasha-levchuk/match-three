extends Node
class_name Raycaster
@onready var block := owner as Block


func get_block_at_point(offset: Vector2i) -> Block:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = block.position + offset * block.size
	var result := block.get_world_2d().direct_space_state.intersect_point(params)
	if result.is_empty(): return null
	var node: Node = result.pop_back().collider
	if not node is Block: return null
	var neighbor := node as Block
	#if not neighbor.state == Block.State.IDLE: return null
	#add_sibling(%Dot.duplicate().place(params.position))
	return neighbor


func get_neighbor(direction: Vector2i) -> Block:
	if direction==Vector2i.UP: direction *= 10
	var where_to := block.position + direction * block.size * 2
	var params := PhysicsRayQueryParameters2D.create(block.position, where_to)
	var result := block.get_world_2d().direct_space_state.intersect_ray(params)
	if result.is_empty(): return null
	var neighbor := result.collider as Block
	return neighbor


func get_neighbor_of_type(direction: Vector2i, type: Matchable.Type) -> Block:
	var neighbor := get_neighbor(direction)
	if neighbor and neighbor.matchable \
	and neighbor.matchable.type == type \
	and neighbor.state == Block.State.IDLE:
		return neighbor
	return null


func gather_neighbors_toward(direction: Vector2i, type: Matchable.Type, \
	neighbors := [] as Array[Block]) -> Array[Block]:
	var neighbor := get_neighbor_of_type(direction, type)
	if neighbor:
		neighbors.append(neighbor)
		neighbor.raycaster.gather_neighbors_toward(direction, type, neighbors)
	return neighbors
