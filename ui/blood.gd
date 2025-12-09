extends Control

@onready var health_label: Label = $HealthLabel

func _ready():
	# Wait for one frame to ensure the Player is ready
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if not player.is_connected("health_changed", update_health):
			player.health_changed.connect(update_health)
		# Initialize
		update_health(player.health, player.max_health)
	else:
		print("UI: Player not found")

func update_health(current, max_val) -> void:
	if health_label:
		health_label.text = "Health: " + str(current) + " / " + str(max_val)
