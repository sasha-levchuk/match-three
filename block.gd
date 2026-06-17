@abstract class_name Block extends CharacterBody2D
static var count: int:
	get():
		count += 1
		return count
var speed: float
@onready var sprite: BlockSprite = get_children().filter(func(c): return c is BlockSprite).pop_back()


func _process(delta: float) -> void:
	speed += delta * 4444
	var collision := move_and_collide(Vector2.DOWN * delta * speed)
	if not collision: return
	if collision.get_collider().is_processing(): return
	Event.collision.emit(self)

