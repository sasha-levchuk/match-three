@tool
extends EditorScript


func _run() -> void:
	for i in 4:
		prints(i)
	prints(Vector2.from_angle(0))
