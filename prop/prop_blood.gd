extends Node2D

@export var item_type: String = "speed"
@export var heal_amount: int = 1

func _ready():
	var area = find_child("Area2D")
	if area:
		area.body_entered.connect(_on_body_entered)
	else:
		for child in get_children():
			if child is Area2D:
				child.body_entered.connect(_on_body_entered)
				break

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("add_health"):
		body.add_health(heal_amount)
		queue_free()
