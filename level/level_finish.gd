extends Node2D

func _ready():
	var camera = get_tree().get_first_node_in_group("player").get_node("Camera2D")
	if camera:
		camera.limit_right = 1152
	print("Game Finished! Victory!")
	# UI is now handled in the scene file

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			# Return to main menu
			if ResourceLoader.exists("res://main.tscn"):
				get_tree().change_scene_to_file("res://main.tscn")
			else:
				print("Main scene not found, quitting.")
				get_tree().quit()
