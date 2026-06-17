extends Node

var zoom: Vector2

func slow_down_time():
	Engine.time_scale = .1
	create_tween().tween_property(Engine, 'time_scale', 1, 1)
