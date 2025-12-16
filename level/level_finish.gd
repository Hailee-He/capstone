extends Node2D

func _ready() -> void:
	# Optional: stop current BGM first to make the finish music cleaner.
	# (If you want a smooth transition, keep fade_sec > 0.)
	AudioManager.stop_bgm(0.4)

	# Play a short victory jingle (one-shot).
	AudioManager.play_jingle("clear", -6.0)

	# Then start the finish BGM (looping/long track).
	AudioManager.play_bgm("finish", 0.6)

	# Safely set camera limit.
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var camera := player.get_node_or_null("Camera2D")
		if camera:
			camera.limit_right = 1152

	print("Game Finished! Victory!")
	# UI is now handled in the scene file


func _input(event) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			# Return to main menu.
			get_tree().change_scene_to_file("res://main.tscn")
