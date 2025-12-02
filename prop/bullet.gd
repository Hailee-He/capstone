extends Node2D

const SPEED: float = 700.0
var direction := Vector2.RIGHT
var damage: int = 1


func _process(delta: float) -> void:
	position += direction * SPEED * delta
	
	var viewport_size := get_viewport_rect().size
	if position.x < -50 or position.x > viewport_size.x + 50 or \
	   position.y < -50 or position.y > viewport_size.y + 50:
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	elif body.has_method("take_demage"): # Compatibility
		body.take_demage(damage)
	queue_free()


func _on_area_2d_area_entered(other_area: Area2D) -> void:
	var parent := other_area.get_parent()
	if parent and parent.has_method("take_demage"):
		parent.take_demage(damage)
	queue_free()
