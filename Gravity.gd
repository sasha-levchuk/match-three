class_name Gravity extends Node
var time := .2
@onready var block := owner as Block


func fall(delay := 0.0):
	block.state = Block.State.FALLING
	block.collider.scale.x = 0.5
	if delay:
		await get_tree().create_timer(delay).timeout
	if block.move_and_collide(Vector2.DOWN):
		block.state = Block.State.IDLE
		return
	set_process(true)
	await get_tree().create_timer(0.05).timeout
	block.send_collapse_impulse_up()


func _process(delta):
	time += delta
	var collision := block.move_and_collide(Vector2.DOWN * time * 200)
	if not collision: return
	time = 0
	var body := collision.get_collider()
	if body is Block:
		if body.state == Block.State.FALLING: return
	set_process(false)
	block.collider.scale.x = 1
	block._on_fall_down()
