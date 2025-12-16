extends Node2D

func _ready() -> void:
	# Start BGM immediately (do this BEFORE any awaits).
	AudioManager.play_bgm("level_04", 0.6)

	# Safely find the player and camera (avoid null errors that stop _ready()).
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var camera := player.get_node_or_null("Camera2D")
		if camera:
			camera.limit_right = 5000

	# Keep your original timing/spawn logic.
	await get_tree().create_timer(0.5).timeout
	spawn_enemies()


func spawn_enemies() -> void:
	var enemy_land = load("res://character/enemy/enemy_hurt.tscn")

	for i in range(10):
		var enemy_instance = enemy_land.instantiate()
		enemy_instance.position = Vector2(1000.0 + i * 300, 500)
		await get_tree().create_timer(3).timeout
		add_child(enemy_instance)
