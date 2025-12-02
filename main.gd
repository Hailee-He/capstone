extends Control


@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var title: Label = $CenterContainer/VBoxContainer/Title


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	start_button.mouse_entered.connect(_on_start_button_hover)
	start_button.mouse_exited.connect(_on_start_button_unhover)
	quit_button.mouse_entered.connect(_on_quit_button_hover)
	quit_button.mouse_exited.connect(_on_quit_button_unhover)

	_animate_title()
	
	start_button.modulate.a = 0
	quit_button.modulate.a = 0
	await get_tree().process_frame
	_animate_buttons_entrance()


func _animate_title() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title, "position:y", title.position.y - 10, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title, "position:y", title.position.y + 10, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _animate_buttons_entrance() -> void:
	var tween = create_tween()
	tween.tween_property(start_button, "modulate:a", 1.0, 0.5).set_delay(0.3)
	tween.parallel().tween_property(start_button, "position:x", start_button.position.x, 0.5).from(start_button.position.x - 100).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(quit_button, "modulate:a", 1.0, 0.5).set_delay(0.1)
	tween.parallel().tween_property(quit_button, "position:x", quit_button.position.x, 0.5).from(quit_button.position.x - 100).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_start_button_hover() -> void:
	var tween = create_tween()
	tween.tween_property(start_button, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_start_button_unhover() -> void:
	var tween = create_tween()
	tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_quit_button_hover() -> void:
	var tween = create_tween()
	tween.tween_property(quit_button, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_quit_button_unhover() -> void:
	var tween = create_tween()
	tween.tween_property(quit_button, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_start_button_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(start_button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_callback(_load_level)


func _load_level() -> void:
	get_tree().change_scene_to_file("res://level/level_1.tscn")


func _on_quit_button_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(quit_button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(quit_button, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_callback(_quit_game)


func _quit_game() -> void:
	get_tree().quit()
