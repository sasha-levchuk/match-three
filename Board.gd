class_name Board extends TileMapLayer

var tiles: Dictionary[Vector2i, Tile]
var is_dragging := false
var dragged_tile: Tile
var drag_offset: Vector2


func _ready() -> void:
	Formation.tiles = tiles
	ExplosionIter.tiles = tiles
	prev_spawned_tiles.resize(get_used_rect().end.x)
	await get_tree().process_frame
	for tile: Tile in get_children():
		var coord := local_to_map(tile.position)
		tile.coord = coord
		tiles[coord] = tile
		for i: int in Matchable.Type.size() - 1:
			if Formation.new(coord).is_found:
				tile.switch_type()
			else:
				break
		tile.set_process(false)
		tile.is_idle = true
		tile.landed.connect(_on_tile_landed.bind(tile))
	%Minimap.setup(tiles)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			on_click()
		elif event.is_released() and is_dragging:
			on_click_released()
	elif event is InputEventMouseMotion and is_dragging:
		on_mouse_motion(event)


func on_click():
	var coord := local_to_map(get_local_mouse_position())
	if not tiles.has(coord) or not tiles[coord] or not tiles[coord].is_idle: return
	
	dragged_tile = tiles[coord]
	drag_offset = Vector2.ZERO
	is_dragging = true
	dragged_tile.is_idle = false
	dragged_tile.sprite.z_index = 2


func on_mouse_motion(event: InputEventMouseMotion):
	drag_offset += event.relative / get_viewport().get_camera_2d().zoom
	dragged_tile.sprite.position = drag_offset
	var axis := drag_offset.abs().max_axis_index()
	if drag_offset.abs()[axis] < tile_set.tile_size.x/2.0: return
	
	is_dragging = false
	var direction := Vector2i.ZERO
	direction[axis] = signi(drag_offset[axis] as int)
	move(dragged_tile, direction)


func move(tile: Tile, direction: Vector2i):
	var origin := local_to_map(tile.position)
	var destination := origin + direction
	if not tiles.has(destination) or not tiles[destination].is_idle:
		await tile.reset_sprite()
		tile.is_idle = true
		return
	
	await swap(origin, destination)
	var move_succeeded: bool
	var batch := Batch.new()
	var holes: Array[Vector2i]
	for coord: Vector2i in [destination, origin]:
		tiles[coord].is_idle = true
		if tiles[coord] is Explosive:
			move_succeeded = true
			continue
		var formation := Formation.new(coord)
		if not formation.is_found: continue
		move_succeeded = true
		if formation.has_reward:
			tiles[coord].queue_free()
			tiles[coord] = spawn_reward_at(coord, formation.reward)
			batch.add_signal(tiles[coord].spawned)
		for hole: Vector2i in formation.matches:
			tiles[hole].get_matched()
			batch.add_signal(tiles[hole].deleted)
		holes.append_array(formation.matches)
	
	if not move_succeeded:
		await swap(origin, destination)
		var coords := [origin, destination]
		coords.sort()
		for coord: Vector2i in coords:
			tiles[coord].is_idle = true
			check_and_fall(coord)
		return
	
	await batch.finished
	cascade_many(holes)
	for coord: Vector2i in [origin, destination]:
		if tiles[coord] and tiles[coord].is_idle:
			check_and_fall(coord)


func swap(start: Vector2i, end: Vector2i) -> Signal:
	var tween := create_tween().set_parallel()
	var tile := tiles[start]
	if tile.sprite.position:
		tile.reset_sprite(tween)
	tiles[end].move(map_to_local(start), tween)
	tiles[end].coord = start
	tiles[start] = tiles[end]
	tile.move(map_to_local(end), tween)
	tile.coord = end
	tiles[end] = tile
	return tween.finished


func cascade(coord: Vector2i):
	var above := coord + Vector2i.UP
	if tiles.has(above):
		if tiles[above] == null or not tiles[above].is_collapsable():
			tiles[coord] = null
			return
		tiles[coord] = tiles[above]
		tiles[coord].fall()
		cascade(above)
	else:
		tiles[coord] = spawn(coord + Vector2i.UP)


var prev_spawned_tiles: Array[Tile]
func spawn(coord: Vector2i) -> Tile:
	var tile := preload("res://matchable.tscn").instantiate() as Tile
	tile.position = map_to_local(coord)
	if is_instance_valid(prev_spawned_tiles[coord.x]):
		var prev_pos := prev_spawned_tiles[coord.x].position
		tile.position.y = min(tile.position.y, prev_pos.y - tile_set.tile_size.y)
		tile.speed = prev_spawned_tiles[coord.x].speed
	add_child(tile)
	prev_spawned_tiles[coord.x] = tile
	tile.landed.connect(_on_tile_landed.bind(tile))
	return tile


func spawn_reward_at(coord: Vector2i, type: Explosive.Type):
	var explosive := preload("res://explosive.tscn").instantiate() as Explosive
	explosive.position = map_to_local(coord)
	explosive.coord = coord
	explosive.type = type
	explosive.sprite.frame = 6 + int(type)
	add_child(explosive)
	explosive.landed.connect(_on_tile_landed.bind(explosive))
	return explosive


func _on_tile_landed(tile: Tile):
	var coord := local_to_map(tile.position)
	if not tiles.has(coord) or tiles[coord] != tile: return
	
	tile.coord = coord
	tile.speed = .0
	tile.position = map_to_local(coord)
	tile.set_process(false)
	tile.is_idle = true
	if not tile is Matchable: return
	
	var formation := Formation.new(coord)
	if not formation.is_found: return
	
	var batch := Batch.new()
	if formation.has_reward:
		tile.queue_free()
		tiles[coord] = spawn_reward_at(coord, formation.reward)
		batch.add_signal(tiles[coord].spawned)
	for hole: Vector2i in formation.matches:
		tiles[hole].get_matched()
		batch.add_signal(tiles[hole].deleted)
	await batch.finished
	if tiles[coord].is_idle:
		check_and_fall(coord)
	cascade_many(formation.matches)


func check_and_fall(coord: Vector2i):
	coord += Vector2i.DOWN
	if tiles.has(coord) and tiles[coord]==null:
		cascade(coord)
		check_and_fall(coord)


func cascade_many(holes: Array[Vector2i]):
	holes.sort()
	var prev_coord := holes[0]
	for coord: Vector2i in holes:
		tiles[coord].queue_free_after_animation()
		if coord - prev_coord != Vector2i.DOWN:
			check_and_fall(prev_coord)
		cascade(coord)
		prev_coord = coord
	check_and_fall(prev_coord)


func on_click_released():
	is_dragging = false
	drag_offset = Vector2.ZERO
	if dragged_tile is Matchable:
		var tile := dragged_tile
		await tile.reset_sprite()
		tile.is_idle = true
		check_and_fall(tile.coord)
		return
	
	dragged_tile.explode()
	var batch := Batch.new()
	batch.add_signal(dragged_tile.deleted)
	var holes: Array[Vector2i]
	holes.append(dragged_tile.coord)
	var explosives_chained: Array[Explosive]
	explosives_chained.append(dragged_tile)
	while explosives_chained:
		var explosive := explosives_chained.pop_front() as Explosive
		prints('processing explosive', explosive)
		for tile: Tile in ExplosionIter.new(explosive.coord, 4, 1):
			batch.add_signal(tile.deleted)
			holes.append(tile.coord)
			prints(tile, 'coord is', tile.coord, tiles.find_key(tile))
			tile.is_idle = false
			explosive.exploded.connect(tile.get_hit)
			if tile is Explosive:
				prints('explosive', tile, 'chained')
				explosives_chained.append(tile)
	
	await batch.finished
	cascade_many(holes)



