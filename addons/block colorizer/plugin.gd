@tool
extends EditorPlugin
var button


func _enter_tree():
	button = Button.new()
	button.text = "Color Blocks"
	button.connect("pressed", Callable(self, "_on_button_pressed"))
	add_control_to_container(CONTAINER_TOOLBAR, button)


func _exit_tree():
	remove_control_from_container(CONTAINER_TOOLBAR, button)
	button.free()


func _on_button_pressed():
	if true: return
	for node: Node in EditorInterface.get_edited_scene_root().get_children():
		if node is Block:
			var block := node as Block
			block.matchable.frame = block.matchable.frame_offset + \
				block.matchable.type as int
	print("You pressed the button!")
