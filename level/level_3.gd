extends Node2D

func _ready() -> void:
	# Start level BGM immediately when the scene loads.
	AudioManager.play_bgm("level_03", 0.6)

	var player := get_tree().get_first_node_in_group("player")
	if player:
		var camera := player.get_node_or_null("Camera2D")
		if camera:
			camera.limit_right = 4000

	await get_tree().create_timer(8).timeout
	spawn_enemies()

func spawn_enemies() -> void:
	var enemy_land = load("res://character/enemy/enemy_land.tscn")
	for i in range(10):
		var enemy_instance = enemy_land.instantiate()
		enemy_instance.position = Vector2(1750.0 + i * 30, 500)
		await get_tree().create_timer(1.5).timeout
		add_child(enemy_instance)
