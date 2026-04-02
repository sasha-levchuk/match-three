class_name Piece extends Area2D
static var n_blocks := 0
@export var matchable: Matchable
enum Type{MATCHABLE, POWERUP, OBJECTIVE, DESTRUCTIBLE}
var type: Type
enum SubType{SKULL, FIRE, ICE, SPIRAL, DISCOBALL, TNT, ROCKETV, ROCKETH, FAN}
var subtype: SubType
const GRAVITY := 2200.0 # speed increase per second
var velocity := 0.0 # pixels per second
@export var sprite: Sprite2D
signal departed
signal dragged(direction: Vector2i)
func _to_string(): return str(name)


func _ready():
	n_blocks += 1
	name = 'B' + str(n_blocks).pad_zeros(3)
	%Label.text = name
	area_entered.connect(_on_collision)


func _process(delta: float):
	velocity += delta * GRAVITY
	position = position.move_toward(Vector2.ZERO, velocity*delta)
	if position == Vector2.ZERO:
		velocity = 0.0
		set_process(false)
		get_parent().state = Slot.State.READY


func _on_collision(piece: Piece):
	if position < piece.position:
		set_deferred('velocity', piece.velocity)
		piece.velocity = velocity


func snap() -> Signal:
	var tween := create_tween()
	tween.tween_property(self, 'position', Vector2.ZERO, 0.2)
	return tween.finished
