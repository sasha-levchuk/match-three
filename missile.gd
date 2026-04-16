class_name Missile extends Sprite2D
var velocity: Vector2
const ACCEL := 3333
const MAX_SPEED := 1111
var target: Slot
@onready var target_pos := position + (Vector2.ONE*100).rotated(randf()*TAU)
var is_taking_off := true
signal target_requested
var rotation_speed: float
@onready var rotation_direction := signf(randf()-.5)


func _process(delta: float):
	rotation_speed = min(rotation_speed + delta * 55, TAU*4)
	rotation += rotation_speed * delta * rotation_direction
	var local_pos := target_pos - position
	var desired_vel := local_pos.normalized() * MAX_SPEED
	velocity = velocity.move_toward(desired_vel, delta * ACCEL)
	position += velocity * delta
	if local_pos.length() < 50:
		if is_taking_off:
			is_taking_off = false
			target_requested.emit()
		elif target and target.is_valid_target():
			print('BOOM')
			target.piece.explode()
			queue_free()
		else:
			target_requested.emit()
