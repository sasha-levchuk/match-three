@tool
extends EditorScript

func _run():
	for node in get_scene().get_children():
		if node is Block:
			node.modulate = node.type_colors[node.type]
