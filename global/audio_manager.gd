# res://global/audio_manager.gd
extends Node
# AudioManager (autoload singleton)
# - Handles BGM (looping), Jingles (one-shot music stingers), and SFX (polyphonic).
# - Fixes the common "new BGM gets stopped by old fade-out tween" issue by managing tweens safely.

# --- Change these paths if your folders are different ---
const BASE_BGM := "res://asset/audio/bgm/"
const BASE_JINGLE := "res://asset/audio/jingle/"
const BASE_SFX := "res://asset/audio/sfx/"

# --- Your existing files (mapped by keys) ---
const BGM := {
	"menu":     BASE_BGM + "bgm_menu.mp3",
	"finish":   BASE_BGM + "bgm_finish.mp3",
	"level_01": BASE_BGM + "level_01.ogg",
	"level_02": BASE_BGM + "level_02.ogg",
	"level_03": BASE_BGM + "level_03.ogg",
	"level_04": BASE_BGM + "level_04.ogg",
}

const JINGLE := {
	"clear":    BASE_JINGLE + "jingle_clear.wav",
	"gameover": BASE_JINGLE + "jingle_gameover.mp3",
}

const SFX := {
	"boom":        BASE_SFX + "boom.wav",
	"footstep":    BASE_SFX + "footstep.mp3",
	"hit":         BASE_SFX + "hit.wav",
	"pickup":      BASE_SFX + "pickup.wav",
	"player_die":  BASE_SFX + "player_die.wav",
	"player_hurt": BASE_SFX + "player_hurt.wav",
	"shoot":       BASE_SFX + "shoot.wav",
	"ui_click":    BASE_SFX + "ui_click.wav",
}

# Recommended: create two buses in Audio Bus Layout: "Music" and "SFX"
@export var music_bus: StringName = &"Music"
@export var sfx_bus: StringName = &"SFX"

@export var music_volume_db: float = -8.0
@export var jingle_volume_db: float = -6.0

# How many simultaneous SFX can overlap (shoot + hit + boom, etc.)
@export var sfx_polyphony: int = 8

var _music: AudioStreamPlayer
var _jingle: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []

var _current_bgm_key: String = ""
var _sfx_next_allowed_ms: Dictionary = {} # key -> next allowed time (ms)

# We keep a reference to the current music tween, so we can cancel it safely.
var _music_tween: Tween = null

func _ready() -> void:
	# Create players at runtime (no scene nodes needed).
	_music = AudioStreamPlayer.new()
	_jingle = AudioStreamPlayer.new()
	add_child(_music)
	add_child(_jingle)

	# Route to buses (must exist in Audio Bus Layout).
	_music.bus = music_bus
	_jingle.bus = music_bus

	# Start silent to avoid pops.
	_music.volume_db = -80.0
	_jingle.volume_db = jingle_volume_db

	# Create a small pool for SFX so multiple sounds can overlap.
	for i in range(sfx_polyphony):
		var p := AudioStreamPlayer.new()
		p.bus = sfx_bus
		p.volume_db = 0.0
		add_child(p)
		_sfx_players.append(p)

# ---------- BGM ----------
func play_bgm(key: String, fade_sec: float = 0.6) -> void:
	# Validate key.
	if not BGM.has(key):
		push_warning("AudioManager: Unknown BGM key: " + key)
		return
	if key == _current_bgm_key:
		return

	# Load stream.
	var path: String = BGM[key]
	var stream := load(path)
	if stream == null:
		push_warning("AudioManager: BGM file not found: " + path)
		return

	_current_bgm_key = key

	# IMPORTANT:
	# Cancel any previous fade tween, otherwise a delayed "stop()" from an old tween
	# can stop the new track after a scene change.
	_kill_music_tween()

	# Switch track immediately on the same player, then fade in.
	_music.stop()
	_music.stream = stream
	_music.volume_db = -80.0
	_music.play()

	# Fade in to target volume.
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", music_volume_db, max(fade_sec, 0.01))

func stop_bgm(fade_sec: float = 0.4) -> void:
	if not _music.playing:
		_current_bgm_key = ""
		return

	_kill_music_tween()

	# Fade out then stop.
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", -80.0, max(fade_sec, 0.01))
	_music_tween.tween_callback(func() -> void:
		_music.stop()
		_current_bgm_key = ""
	)

func _kill_music_tween() -> void:
	# Helper: safely kill running tween to avoid conflicts.
	if _music_tween and _music_tween.is_running():
		_music_tween.kill()
	_music_tween = null

# ---------- Jingle ----------
func play_jingle(key: String, volume_db: float = -6.0) -> void:
	# Jingles are short one-shot clips (do not fade BGM here; you can do that externally if desired).
	if not JINGLE.has(key):
		push_warning("AudioManager: Unknown Jingle key: " + key)
		return

	var path: String = JINGLE[key]
	var stream := load(path)
	if stream == null:
		push_warning("AudioManager: Jingle file not found: " + path)
		return

	_jingle.stop()
	_jingle.stream = stream
	_jingle.volume_db = volume_db
	_jingle.play()

# ---------- SFX ----------
func play_sfx(key: String, volume_db: float = 0.0, cooldown_sec: float = 0.0) -> void:
	# Optional cooldown to avoid noisy spam.
	var now_ms := Time.get_ticks_msec()
	if cooldown_sec > 0.0:
		var next_ms := int(_sfx_next_allowed_ms.get(key, 0))
		if now_ms < next_ms:
			return
		_sfx_next_allowed_ms[key] = now_ms + int(cooldown_sec * 1000.0)

	if not SFX.has(key):
		push_warning("AudioManager: Unknown SFX key: " + key)
		return

	var path: String = SFX[key]
	var stream := load(path)
	if stream == null:
		push_warning("AudioManager: SFX file not found: " + path)
		return

	# Find a free player; if none are free, reuse the first one.
	var p: AudioStreamPlayer = _sfx_players[0]
	for sp in _sfx_players:
		if not sp.playing:
			p = sp
			break

	p.stream = stream
	p.volume_db = volume_db
	p.play()
