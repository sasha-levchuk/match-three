class_name BlockSprite extends Sprite2D

const TWEEN_TIME := .1

@export var deletion_flash: Polygon2D


func animate_reset(tw := create_tween().set_parallel(true)) -> Tween:
	tw.tween_property(self, 'scale', Vector2.ONE, TWEEN_TIME)
	tw.tween_property(self, 'z_index', 0, TWEEN_TIME)
	tw.tween_property(self, 'offset', Vector2.ZERO, TWEEN_TIME)
	return tw


func animate_delete(tw := create_tween().set_parallel(true)) -> Tween:
	deletion_flash.show()
	tw.tween_property(self, 'modulate:a', 0, TWEEN_TIME)
	return tw


func animate_spawn(tw := create_tween().set_parallel(true)) -> Tween:
	tw.tween_property(self, 'scale', Vector2.ONE, TWEEN_TIME)
	tw.tween_property(self, 'z_index', 0, TWEEN_TIME)
	tw.tween_property(self, 'offset', Vector2.ZERO, TWEEN_TIME)
	return tw



