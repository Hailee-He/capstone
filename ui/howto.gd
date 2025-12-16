# res://ui/howto.gd
extends Control

@export var back_button: Button
const MAIN_SCENE_PATH := "res://main.tscn"

# Store the previous target music volume so we can restore it when leaving this scene.
var _prev_music_db: float = -8.0

# Target lower volume while reading "How to Play"
@export var howto_music_db: float = -18.0

func _ready() -> void:
	# Remember the current configured BGM volume (AudioManager's target volume).
	_prev_music_db = AudioManager.music_volume_db

	# Lower the configured volume for the current BGM.
	AudioManager.music_volume_db = howto_music_db

	# Apply the new volume without restarting the music:
	# If the same BGM key is already playing, play_bgm() will early-return,
	# so it won't restart. We just want the new volume to take effect.
	AudioManager.play_bgm("menu", 0.0)

	# Hook up button events.
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		back_button.mouse_entered.connect(_on_button_hover)
		back_button.focus_entered.connect(_on_button_hover)
	else:
		push_warning("HowTo: back_button is not assigned in the Inspector.")

func _unhandled_input(event: InputEvent) -> void:
	# Press ESC to go back (ui_cancel is usually mapped to Esc by default).
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _exit_tree() -> void:
	# Restore the configured music volume when leaving this scene.
	AudioManager.music_volume_db = _prev_music_db

	# Apply restored volume without restarting the track.
	AudioManager.play_bgm("menu", 0.0)

func _on_button_hover() -> void:
	# UI hover sound (cooldown prevents spam).
	AudioManager.play_sfx("ui_click", -6.0, 0.05)

func _on_back_pressed() -> void:
	# Click sound, then go back to main menu.
	AudioManager.play_sfx("ui_click", -6.0, 0.05)

	# Tiny delay so the click sound can be heard before changing scenes.
	await get_tree().create_timer(0.05).timeout
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)
