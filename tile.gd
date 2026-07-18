class_name Tile extends CharacterBody2D

const TWEEN_TIME := .1

@export var anim_player: AnimationPlayer
@export var sprite: Sprite2D
@export var label: Label

var is_idle := false:
	set(val):
		is_idle = val
		%BusyLabel.text = &'idle' if is_idle else &'busy'
		%BusyFill.color = Color.TRANSPARENT if is_idle else Color(1.0, 0.0, 0.0, 0.22)
var speed := 0.0
var coord: Vector2i:
	set(new_coord):
		coord = new_coord
		%CoordLabel.text = str(coord)

signal landed
signal deleted


func _ready() -> void:
	label.text = ''
	for i in 3:
		label.text += char(ord('a') + randi()%25)
	name = label.text


func _to_string() -> String:
	return label.text


func delete():
	is_idle = false
	anim_player.play('delete')
	await anim_player.animation_finished
	#this might cause bugs, as a tile might fall through this shape
	#%CollisionShape.disabled = true
	deleted.emit()
	anim_player.play('fade')


func get_matched():
	%Flash.show()
	%Flash.color = Color(0.238, 0.403, 0.0, 1.0)
	delete()


func get_hit():
	%Flash.show()
	%Flash.color = Color(0.824, 0.435, 0.0, 1.0)
	delete()


func fall():
	is_idle = false
	set_process(true)


func _process(delta: float) -> void:
	speed += delta * 5555
	var collision := move_and_collide(Vector2.DOWN * speed * delta)
	if collision and not collision.get_collider().is_processing():
		speed = 0.0
		landed.emit()


func reset_sprite(tween := create_tween()) -> Signal:
	tween.tween_property(sprite, 'position', Vector2.ZERO, TWEEN_TIME)
	tween.finished.connect(func(): sprite.z_index = 0, CONNECT_ONE_SHOT)
	return tween.finished


func move(new_pos: Vector2, tween: Tween):
	is_idle = false
	tween.tween_property(self, 'position', new_pos, TWEEN_TIME)
	tween.tween_property(sprite, 'position', Vector2.ZERO, TWEEN_TIME)


func is_collapsable() -> bool:
	return is_processing() or is_idle


func queue_free_after_animation():
	%CollisionShape.disabled = true
	while anim_player.current_animation:
		await anim_player.animation_finished
	await get_tree().process_frame
	queue_free()
