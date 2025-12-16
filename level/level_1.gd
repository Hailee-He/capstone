extends Node2D

func _ready() -> void:
	# Safely find the player and camera (avoid null errors that stop _ready()).
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var camera := player.get_node_or_null("Camera2D")
		if camera:
			camera.limit_right = 2000

	# Wait one frame to ensure AudioManager + audio server are ready after scene change.
	await get_tree().process_frame

	# Start level 1 BGM.
	AudioManager.play_bgm("level_01", 0.6)
