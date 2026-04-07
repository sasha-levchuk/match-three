"
class_name Gravity extends Node
var time := .2
@onready var block := owner as Block


func fall(delay := 0.0):
	block.state = Block.State.FALLING
	if delay:
		await get_tree().create_timer(delay).timeout
	block.collider.scale.x = 0.5
	if block.move_and_collide(Vector2.DOWN, true):
		block.state = Block.State.IDLE
		return
	set_process(true)
	await get_tree().create_timer(0.05).timeout
	block.collapse_upward()


func _process(delta):
	time += delta
	var collision := block.move_and_collide(Vector2.DOWN * time * 200)
	if not collision: return
	time = 0
	var body := collision.get_collider()
	if body is Block:
		if body.state == Block.State.FALLING: 
			return
	set_process(false)
	block.collider.scale.x = 1.0
	if block.matchable:
		var result = block.matchable.find_matches()
		if result.is_success:
			block.apply_result(result)
		else:
			block.state = Block.State.IDLE
	else:
		block.state = Block.State.IDLE
"
