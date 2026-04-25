extends TileMapLayer

var slots: Dictionary[Vector2i, Slot]
var sides: Array[Vector2i] = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT]
@onready var tilesize := tile_set.tile_size as Vector2
var prev_pieces:Array[Piece]
var size: Vector2i


func _ready():
	Event.reset_requested.connect(_on_reset_requested)
	await get_tree().process_frame
	for slot: Slot in get_children():
		var coord := Vector2i(slot.position/tilesize)
		size = size.max(coord)
		slots[coord] = slot
		#slot.get_node('CoordLabel').text = str(coord.x) + ' ' + str(coord.y)
		slot.piece_requested.connect(_on_piece_requested.bind(coord))
		slot.piece_landed.connect(_on_piece_landed.bind(coord))
		slot.piece_moved.connect(_on_piece_moved.bind(coord))
		slot.piece_triggered.connect(_on_piece_triggered.bind(coord))
	size += Vector2i.ONE
	prev_pieces.resize(size.x)
	gather_pieces()


func gather_pieces():
	var premade_pieces: Dictionary[Vector2, Piece]
	for piece: Piece in %PiecesLayer.get_children():
		if piece.is_objective: Game.crystals += 1
		premade_pieces[piece.position] = piece
	Event.score_updated.emit()
	for slot: Slot in slots.values():
		if premade_pieces.has(slot.position):
			slot.acquire_fall(premade_pieces[slot.position])
		else:
			slot.piece_requested.emit()


func _on_reset_requested():
	Game.crystals = 0
	for slot: Slot in slots.values():
		if slot.piece: slot.piece.queue_free()
	await get_tree().process_frame
	var pattern := tile_set.get_pattern(0)
	for coord: Vector2i in pattern.get_used_cells():
		%PiecesLayer.erase_cell(coord)
		%PiecesLayer.set_cell(coord, 0, Vector2i.ZERO, pattern.get_cell_alternative_tile(coord))
	await get_tree().process_frame
	gather_pieces()


func _on_piece_requested(coord: Vector2i):
	var row := coord.y
	while row:
		row -= 1
		var piece := slots[Vector2i(coord.x, row)].piece
		if not piece: continue
		if piece.is_idle or piece.state==Piece.State.FALLING:
			piece.departed.emit()
			slots[coord].acquire_fall(piece)
			return
		return
	slots[coord].acquire_fall(spawn_piece(coord.x))


func _on_piece_landed(piece: Piece, coord: Vector2i):
	var is_success := is_match(coord)
	if not is_success:
		piece.state = Piece.State.IDLE


func is_match(coord: Vector2i) -> bool:
	var type := slots[coord].piece.type
	var matches: Dictionary[Vector2i, Array]
	for side: Vector2i in sides:
		matches[side] = []
		var counter := 1
		while match_and_append(matches[side], coord+side*counter, type):
			counter += 1
	var result: Array
	var horizontal := matches[Vector2i.LEFT] + matches[Vector2i.RIGHT]
	var vertical := matches[Vector2i.UP] + matches[Vector2i.DOWN]
	var all := horizontal + vertical
	if horizontal.size() >= 4 or vertical.size() >= 4:
		result = all
		slots[coord].piece.make_powerup(Piece.PowerupType.DISCOBALL)
	elif horizontal.size() >= 2 and vertical.size() >= 2:
		result = all
		slots[coord].piece.make_powerup(Piece.PowerupType.TNT)
	elif horizontal.size() >= 3:
		result = horizontal
		slots[coord].piece.make_powerup(Piece.PowerupType.ROCKETV)
	elif vertical.size() >= 3:
		result = vertical
		slots[coord].piece.make_powerup(Piece.PowerupType.ROCKETH)
	else: # fan or just three
		for i in 4: # fan
			var fan_matches: Array[Piece]
			var diag := sides[i] + sides[(i+1)%4]
			if match_and_append(fan_matches, coord+diag, type) \
			and matches[sides[i]] and matches[sides[(i+1)%4]]:
				result = fan_matches + matches[sides[i]] + matches[sides[(i+1)%4]]
				slots[coord].piece.make_powerup(Piece.PowerupType.POOFY)
				break
		if not result: # no fan detected, try 3 in a row
			if horizontal.size() >= 2:
				result = horizontal + [slots[coord].piece]
			elif vertical.size() >= 2:
				result = vertical + [slots[coord].piece]
	if result:
		for piece: Piece in result:
			piece.delete()
		return true
	return false


func match_and_append(arr: Array, coord: Vector2i, type: Piece.Type)->bool:
	if is_valid(coord) and slots[coord].piece.is_matchable \
	and slots[coord].piece.type==type:
		arr.append(slots[coord].piece)
		return true
	return false


func _on_piece_moved(direction: Vector2i, coord: Vector2i):
	var slot := slots[coord]
	if not is_valid(coord+direction): return
	var slot2 := slots[coord+direction]
	if slot.piece.is_powerup and slot2.piece.is_powerup:
		slot2.piece.delete()
		await slot.piece.move(slot2.position)
		slot.piece.delete()
		powerup_combine([slot.piece.powerup_type, slot2.piece.powerup_type], coord+direction)
		return
	slot.acquire_move(slot2.piece)
	await slot2.acquire_move(slot.piece)
	if slot.piece.is_powerup:
		is_match(coord+direction)
		slot.piece.explode()
	elif slot2.piece.is_powerup:
		is_match(coord)
		slot2.piece.explode()
	else:
		var is_success := is_match(coord) if slot.piece.is_matchable else true
		var is_success2 := is_match(coord+direction) if slot2.piece.is_matchable else true
		if not is_success and not is_success2:
			slot.acquire_move(slot2.piece)
			slot2.acquire_move(slot.piece)


func is_valid(coord: Vector2i):
	var slot := slots.get(coord) as Slot
	return slot and slot.piece and slot.piece.is_idle


func spawn_piece(col: int) -> Piece:
	var new_piece = load("res://piece.tscn").instantiate() as Piece
	new_piece.add_to_group(Group.MATCHABLES)
	var pos := Vector2.RIGHT*col*tilesize + tilesize/2 + tilesize*Vector2.UP
	var piece := prev_pieces[col]
	if piece and is_instance_valid(piece) and piece.position.y-pos.y<tilesize.y:
		pos = piece.position + tilesize*Vector2.UP
	new_piece.position = pos
	add_child(new_piece)
	prev_pieces[col] = new_piece
	return new_piece


func _on_piece_triggered(powerup_type: Piece.PowerupType, coord: Vector2i):
	prints('on piece triggered', coord, powerup_type)
	match powerup_type:
		Piece.PowerupType.DISCOBALL:
			var type := Piece.Type.values().pick_random() as Piece.Type
			get_tree().call_group(Group.MATCHABLES, 'delete_type', type)
		Piece.PowerupType.TNT:
			prints('tnt triggered at', coord)
			delete_square(coord, 5, 5)
		Piece.PowerupType.ROCKETV:
			delete_square(coord, 1, 22)
		Piece.PowerupType.ROCKETH:
			delete_square(coord, 22, 1)
		Piece.PowerupType.POOFY:
			prints('single poofy')
			Missile.make(slots[coord].position)
			delete_square(coord, 3, 1)
			delete_square(coord, 1, 3)


func powerup_combine(types: Array[Piece.PowerupType], coord: Vector2i):
	types.sort()
	prints('combo', types, 'at', coord)
	match types:
		[Piece.PowerupType.DISCOBALL, Piece.PowerupType.DISCOBALL]:
			var type := Piece.Type.values().pick_random() as Piece.Type
			var type2 := Piece.Type.values().pick_random() as Piece.Type
			while type == type2:
				type2 = Piece.Type.values().pick_random() as Piece.Type
			get_tree().call_group(Group.MATCHABLES, 'delete_type', type)
			get_tree().call_group(Group.MATCHABLES, 'delete_type', type2)
		[Piece.PowerupType.DISCOBALL, Piece.PowerupType.TNT]:
			var type := get_most_used_type()
			for piece: Piece in get_tree().get_nodes_in_group(Group.MATCHABLES):
				if piece.type==type and piece.is_idle:
					piece.make_powerup_and_explode(Piece.PowerupType.TNT)
			#get_tree().call_group(Group.MATCHABLE, 'explode_type', type, Piece.PowerupType.TNT)
		[Piece.PowerupType.DISCOBALL, Piece.PowerupType.ROCKETV],\
		[Piece.PowerupType.DISCOBALL, Piece.PowerupType.ROCKETH]:
			var type := get_most_used_type()
			for piece: Piece in get_tree().get_nodes_in_group(Group.MATCHABLES):
				if piece.type==type and piece.is_idle:
					var powerup := Piece.PowerupType.ROCKETV
					if randi()%2: powerup = Piece.PowerupType.ROCKETH
					piece.make_powerup_and_explode(powerup)
		[Piece.PowerupType.DISCOBALL, Piece.PowerupType.POOFY]:
			var type := get_most_used_type()
			for piece: Piece in get_tree().get_nodes_in_group(Group.MATCHABLES):
				if piece.type==type and piece.is_idle:
					piece.delete(4).tween_callback(Missile.make.bind(piece.position))
		[Piece.PowerupType.TNT, Piece.PowerupType.TNT]:
			delete_square(coord, 6, 6)
		[Piece.PowerupType.TNT, Piece.PowerupType.ROCKETV],\
		[Piece.PowerupType.TNT, Piece.PowerupType.ROCKETH]:
			delete_square(coord, 3, 22)
			delete_square(coord, 22, 3)
		[Piece.PowerupType.TNT, Piece.PowerupType.POOFY]:
			Missile.make(slots[coord].position, true, Piece.PowerupType.TNT)
		[Piece.PowerupType.ROCKETV, Piece.PowerupType.ROCKETV],\
		[Piece.PowerupType.ROCKETH, Piece.PowerupType.ROCKETH],\
		[Piece.PowerupType.ROCKETV, Piece.PowerupType.ROCKETH]:
			delete_square(coord, 1, 22)
			delete_square(coord, 22, 1)
		[Piece.PowerupType.ROCKETV, Piece.PowerupType.POOFY]:
			Missile.make(slots[coord].position, true, Piece.PowerupType.ROCKETV, target_finder_column)
		[Piece.PowerupType.ROCKETH, Piece.PowerupType.POOFY]:
			Missile.make(slots[coord].position, true, Piece.PowerupType.ROCKETH)
		[Piece.PowerupType.POOFY, Piece.PowerupType.POOFY]:
			prints('double poofy')
			Missile.make(slots[coord].position)
			Missile.make(slots[coord].position)
			Missile.make(slots[coord].position)
			delete_square(coord, 3, 1)
			delete_square(coord, 1, 3)


func delete_square(coord: Vector2i, cols:=1, rows:=1):
	for col: int in range(-cols/2, cols/2+1):
		for row: int in range(-rows/2, rows/2+1):
			var del_coord := coord + Vector2i(col, row)
			if is_valid(del_coord): 
				slots[del_coord].piece.explode()


func get_most_used_type() -> Piece.Type:
	var type_numbers: Dictionary[Piece.Type, int]
	for piece: Piece in get_tree().get_nodes_in_group(Group.MATCHABLES):
		if piece.is_idle:
			if type_numbers.has(piece.type):
				type_numbers[piece.type] += 1
			else:
				type_numbers[piece.type] = 1
	var max_type: Piece.Type
	var max_number := 0
	for type: Piece.Type in type_numbers:
		if type_numbers[type] > max_number:
			max_number = type_numbers[type]
			max_type = type
	return max_type


func target_finder_column() -> Piece:
	var columns: Array[Array]
	columns.resize(size.x)
	for coord: Vector2i in slots:
		var piece: Piece = slots[coord].piece
		if piece and piece.is_objective and piece.is_idle:
			columns[coord.x].append(piece)
	var biggest_size := 0
	for column_array: Array in columns:
		biggest_size = maxi(biggest_size, column_array.size())
	var optimal_targets: Array[Piece]
	for column_array: Array[Piece] in columns:
		if column_array.size() == biggest_size:
			optimal_targets.append_array(column_array)
	return optimal_targets.pick_random() as Piece
