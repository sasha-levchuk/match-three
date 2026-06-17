class_name Spawner extends Area2D
var queue: int
var is_spawning: bool
var prev_block: Matchable


func spawn():
	queue += 1
	if is_spawning: return
	is_spawning = true
	while queue:
		await get_tree().process_frame
		var new_block := preload("res://matchable.tscn").instantiate() as Matchable
		if prev_block: new_block.speed = prev_block.speed
		prev_block = new_block
		add_child(new_block)
		await body_exited
		queue -= 1
	is_spawning = false

