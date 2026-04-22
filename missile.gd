class_name Missile extends Node2D
static var targets: Array[Piece]
const ACCEL := 4444
const MAX_SPEED := 1555
var target: Piece
var rotation_speed: float
var velocity: Vector2
@onready var rotation_direction := signf(randf()-.5) 
@onready var init_target := position + \
	(get_viewport().get_camera_2d().position-position) \
	.normalized().rotated((randf()-.5)*PI)*200
signal target_requested


func _init(pos: Vector2):
	add_child(load("res://missile.tscn").instantiate() as Sprite2D)
	position = pos
	Game.add_child(self)
	target_requested.connect(find_new_target)
	await get_tree().create_timer(randf()).timeout
	while true:
		await get_tree().create_timer(0.2).timeout
		if target and target.is_idle and target.is_objective: continue
		target_requested.emit()


func _physics_process(delta):
	var local_pos := (target.position if target else init_target) - position
	var desired_vel := local_pos.normalized() * MAX_SPEED
	velocity = velocity.move_toward(desired_vel, delta * ACCEL)
	position += velocity * delta
	rotation_speed = min(rotation_speed + delta * 55, TAU*2)
	rotation += rotation_speed * delta * rotation_direction
	if not target: return
	if target.is_idle:
		if target.position.distance_to(position) < 75:
			print('BOOM')
			targets.erase(target)
			target.explode()
			queue_free()
	else:
		targets.erase(target)
		target_requested.emit()


func find_new_target():
	var objectives := get_tree().get_nodes_in_group(Group.OBJECTIVES).filter(
		func(p: Piece): return not targets.has(p) and p.is_idle)
	if objectives:
		target = objectives.pick_random()
		targets.append(target)
		return
	var matchables := get_tree().get_nodes_in_group(Group.MATCHABLES).filter(
		func(p): return not targets.has(p) and p.is_idle)
	if matchables:
		target = matchables.pick_random()
		targets.append(target)
