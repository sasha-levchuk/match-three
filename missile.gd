class_name Missile extends Node2D
static var targets: Array[Piece]
const ACCEL := 4444
const MAX_SPEED := 1555
var target: Piece
var rotation_speed: float
var velocity: Vector2
@export var fan_sprite: Sprite2D
var has_cargo := false
var cargo_type: Piece.PowerupType
var target_finder: Callable = target_finder_default
@export var cargo_sprite: Sprite2D
@onready var rotation_direction := signf(randf()-.5) 
@onready var init_target := position + \
	(get_viewport().get_camera_2d().position-position) \
	.normalized().rotated((randf()-.5)*PI)*200


static func make(pos: Vector2, _has_cargo:=false, _cargo_type:=Piece.PowerupType.POOFY,
	_target_finder:=Callable()):
	var missile := load("res://missile.tscn").instantiate() as Missile
	missile.position = pos
	if _has_cargo:
		missile.has_cargo = _has_cargo
		missile.cargo_type = _cargo_type
		missile.cargo_sprite.show()
		missile.cargo_sprite.frame = 6 + _cargo_type as int
		if _target_finder:
			missile.target_finder = _target_finder
	Game.add_child(missile)


func _ready():
	await get_tree().create_timer( randf() ).timeout
	while true:
		await get_tree().create_timer(0.1).timeout
		if not target or not target.is_idle or not target.is_objective:
			find_new_target()


func _physics_process(delta):
	var local_pos := (target.position if target else init_target) - position
	var desired_vel := local_pos.normalized() * MAX_SPEED
	velocity = velocity.move_toward(desired_vel, delta * ACCEL)
	position += velocity * delta
	rotation_speed = min(rotation_speed + delta * 55, TAU*2)
	fan_sprite.rotation += rotation_speed * delta * rotation_direction
	if not target: return
	if target.position.distance_to(position) < 75:
		if target.is_idle:
			print('BOOM')
			targets.erase(target)
			if has_cargo:
				target.triggered.emit(cargo_type)
			else:
				target.explode()
			queue_free()
		else:
			find_new_target()


func find_new_target():
	target = target_finder.call()


func target_finder_default() -> Piece:
	var objectives := get_tree().get_nodes_in_group(Group.OBJECTIVES).filter(
		func(p: Piece): return not targets.has(p) and p.is_idle)
	if objectives:
		return objectives.pick_random() as Piece
	var matchables := get_tree().get_nodes_in_group(Group.MATCHABLES).filter(
		func(p): return not targets.has(p) and p.is_idle)
	#if matchables:
	return matchables.pick_random() as Piece
