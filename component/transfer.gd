extends Node2D

@export var next_level_path: String = "res://level/level_2.tscn"

func _ready():
	var area = find_child("Area2D")
	if area:
		area.body_entered.connect(_on_body_entered)
	else:
		# Fallback
		for child in get_children():
			if child is Area2D:
				child.body_entered.connect(_on_body_entered)
				break
	
	# Glowing animation
	var tween = create_tween().set_loops()
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5), 1.0)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 1.0)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Transferring to: ", next_level_path)
		call_deferred("change_level")

func change_level():
	if next_level_path and ResourceLoader.exists(next_level_path):
		get_tree().change_scene_to_file(next_level_path)
	else:
		print("Error: Level path not found: ", next_level_path)
