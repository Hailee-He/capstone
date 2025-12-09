extends Node2D

func _ready():
	var camera = get_tree().get_first_node_in_group("player").get_node("Camera2D")
	if camera:
		camera.limit_right = 2000
