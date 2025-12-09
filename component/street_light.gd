extends Node2D

@onready var light_scene_l: Light = $lightSceneL
@onready var light_scene_r: Light = $lightSceneR

func _ready() -> void:
	# Configure streetlight light parameters
	# The streetlights shine downwards with a large angle
	light_scene_l.update_light_params(
		255.0,  # Range
		21.0,   # Angle
		90.0,   # Direction (downwards)
		Color(0.631, 0.631, 0.533, 0.192)  # Light color
	)
	
	light_scene_r.update_light_params(
		255.0,  # Range
		21,     # Angle
		90.0,   # Direction (downwards)
		Color(0.631, 0.631, 0.533, 0.192)  # Light color
	)


func _process(_delta: float) -> void:
	var bodies = light_scene_l.get_bodies_in_light()
	if bodies.size() > 0:
		for body in bodies:
			if body.has_method("on_illuminated"):
				body.on_illuminated()
