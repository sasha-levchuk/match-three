class_name Gravity extends Node
var time: float
@onready var block := owner as Block


func _process(delta):
	time += delta
	var collision := block.move_and_collide(Vector2.DOWN * time * 200)
	if not collision: return
	time = 0
	var body := collision.get_collider()
	if body is Block:
		if body.state == Block.State.FALLING: return
	set_process(false)
	block._on_fall_down()
