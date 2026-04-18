class_name Missile extends Sprite2D
const ACCEL := 3333
const MAX_SPEED := 1555
var target: Piece
signal target_requested
var rotation_speed: float
var velocity: Vector2
@onready var rotation_direction := signf(randf()-.5) 
@onready var init_target := position + \
	(get_viewport().get_camera_2d().position-position) \
	.normalized().rotated((randf()-.5)*PI)*200


func _process(delta: float):
	rotation_speed = min(rotation_speed + delta * 55, TAU*4)
	rotation += rotation_speed * delta * rotation_direction
	var local_pos := (target.position if target else init_target) - position
	var desired_vel := local_pos.normalized() * MAX_SPEED
	velocity = velocity.move_toward(desired_vel, delta * ACCEL)
	position += velocity * delta
	if target and target.state != Piece.State.IDLE:
		target.remove_from_group('missile_targets')
		target_requested.emit()
	elif local_pos.length() < 50:
		if target:
			print('BOOM')
			target.explode()
			queue_free()
		else:
			target_requested.emit()
