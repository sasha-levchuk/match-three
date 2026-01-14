@tool
extends EditorPlugin
var button


func _enter_tree():
	button = Button.new()
	button.text = "Color Blocks"
	button.connect("pressed", Callable(self, "_on_button_pressed"))
	add_control_to_container(CONTAINER_TOOLBAR, button)
	print("Plugin enabled!")


func _exit_tree():
	remove_control_from_container(CONTAINER_TOOLBAR, button)
	button.free()
	print("Plugin disabled!")


func _on_button_pressed():
	for node: Node in EditorInterface.get_edited_scene_root().get_children():
		if node is Block:
			node.modulate = node.type_colors[node.type]
	print("You pressed the button!")
