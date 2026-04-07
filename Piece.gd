class_name Piece extends Area2D
static var n_blocks := 0
var matchable: Matchable
class Matchable:
	enum Type{SKULL,FIRE,ICE,MAGIC}
	var type: Type
var powerup: Powerup
var objective: Objective
class Objective:
	pass
var speed := 0.0
@export var sprite: Sprite2D
var landed: Signal


func _ready():
	n_blocks += 1
	%Label.text = name
	#area_entered.connect(func(piece_below: Piece):
		#if true: return
		#if piece_below.position.y < position.y or not is_processing(): return
		#prints(name, 'entered', piece_below.name)
		#position = piece_below.position + Vector2.UP*Board.TILE_SIZE
		#if piece_below.is_processing():
			#piece_below.speed = speed
	#)


const GRAVITY := 2555.0 # speed increase per second
var fall_target: Vector2
func _process(delta: float):
	speed += delta * GRAVITY
	position = position.move_toward(fall_target, speed * delta)
	if position == fall_target:
		speed = 0.0
		set_process(false)
		landed.emit()


func snap(where: Vector2) -> Signal:
	prints('snapping', name, 'to', where)
	z_index = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, 'position', where, 0.1)
	tween.tween_property(sprite, 'position', Vector2.ZERO, 0.1)
	return tween.finished


func delete():
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0, 0.1)
	await tween.finished
	queue_free()


func setup_matchable():
	matchable = Matchable.new()
	matchable.type = Matchable.Type.values().pick_random() as Matchable.Type
	%Sprite2.frame = 1 + matchable.type as int
	name = Matchable.Type.keys()[matchable.type].left(1) + str(n_blocks).pad_zeros(3)


func setup_powerup(type: Powerup.Type):
	set_process(false)
	powerup = Powerup.new()
	powerup.type = type
	%Sprite.frame = 5 + type as int
	monitoring = false
	set_deferred('monitoring', true)
