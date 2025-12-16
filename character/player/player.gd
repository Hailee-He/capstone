extends CharacterBody2D

var speed: float = 200.0
const JUMP_VELOCITY = -400.0
@onready var flash_light: Light = $FlashLight
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

var health: int = 10
var max_health: int = 10
var current_item: String = ""
var is_invincible: bool = false
var is_dying: bool = false

signal health_changed(current, max)

# ----------------------------
# Audio (minimal additions)
# ----------------------------

# Footstep SFX (plays periodically while walking on the floor)
@export var footstep_interval: float = 0.35
@export var footstep_volume_db: float = -10.0
var _footstep_timer: float = 0.0

# Hurt / death
@export var hurt_volume_db: float = -6.0
@export var hurt_cooldown_sec: float = 0.2
@export var death_sfx_volume_db: float = -4.0

# Jingle for game over
@export var gameover_jingle_volume_db: float = -6.0

# Delay reload so you can hear the jingle/SFX
@export var reload_delay_sec: float = 1.0

func attacked(demage:int):
	take_damage(demage)

func take_damage(amount: int):
	if is_invincible or is_dying:
		return

	# Play hurt SFX (with cooldown to avoid spam).
	AudioManager.play_sfx("player_hurt", hurt_volume_db, hurt_cooldown_sec)

	health -= amount
	Global.player_health = health
	print("blood: ", health)
	_update_health_bar()
	emit_signal("health_changed", health, max_health)
	if health <= 0:
		die()

func _update_health_bar():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

func die():
	if is_dying:
		return
	is_dying = true
	print("Player Died")

	# Play game over jingle + death SFX once.
	AudioManager.play_jingle("gameover", gameover_jingle_volume_db)
	AudioManager.play_sfx("player_die", death_sfx_volume_db)

	Global.player_health = Global.player_max_health
	Global.player_item = ""

	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	hide()

	var tree = get_tree()
	if tree:
		# Delay reload so audio can be heard.
		await tree.create_timer(reload_delay_sec).timeout
		tree.reload_current_scene()

func add_item(type: String):
	current_item = type
	Global.player_item = type
	print("Picked up: ", type)

	# Play pickup SFX.
	AudioManager.play_sfx("pickup", -8.0, 0.1)

func use_next_item():
	if current_item != "":
		use_item(current_item)
		current_item = ""
		Global.player_item = ""

func use_item(type: String):
	print("Used item: ", type)
	match type:
		"boom":
			# Play explosion SFX.
			AudioManager.play_sfx("boom", -3.0, 0.1)

			var flash = Polygon2D.new()
			var points = PackedVector2Array()
			for i in range(32):
				var angle = i * TAU / 32
				points.append(Vector2(cos(angle), sin(angle)) * 100)
			flash.polygon = points
			flash.color = Color(1, 1, 0.8, 0.8)
			flash.position = position
			get_parent().add_child(flash)

			var tween = create_tween()
			tween.tween_property(flash, "modulate:a", 0.0, 0.5)
			tween.tween_callback(flash.queue_free)

			var enemies = get_tree().get_nodes_in_group("enemy")
			for enemy in enemies:
				if enemy is Node2D and global_position.distance_to(enemy.global_position) <= 100.0:
					if enemy.has_method("die"):
						enemy.die()
					else:
						enemy.queue_free()

func _ready() -> void:
	# Load state from Global
	health = Global.player_health
	max_health = Global.player_max_health
	current_item = Global.player_item

	add_to_group("player")
	flash_light.update_light_params(
		150.0,  # Range
		50.0,   # Angle
		0,      # Direction (to the right)
		Color(1.0, 1.0, 0.902, 0.302),
	)

	flash_light.visible = false
	flash_light.monitoring = false  # Disable collision detection
	flash_light.monitorable = false  # Prevent other areas from detecting it
	_update_health_bar()
	emit_signal("health_changed", health, max_health)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("player_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("play_light"):
		flash_light.visible = !flash_light.visible
		flash_light.monitoring = flash_light.visible  # Sync collision detection state
		flash_light.monitorable = flash_light.visible

	if Input.is_action_just_pressed("use_item") or Input.is_action_just_pressed("ui_focus_next"):
		use_next_item()

	var direction := Input.get_axis("player_left", "player_right")

	if direction != 0:
		velocity.x = direction * speed
		# Flip sprite facing direction
		sprite.flip_h = direction < 0
		_turn_light_direction(direction == 1)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

	# Footstep SFX (periodic while walking on the floor).
	_play_footsteps(delta, direction)

# Footstep helper (explicit bool type avoids inference errors)
func _play_footsteps(delta: float, direction: float) -> void:
	if is_dying:
		return

	var is_walking: bool = is_on_floor() and abs(direction) > 0.0 and abs(velocity.x) > 1.0
	if not is_walking:
		_footstep_timer = 0.0
		return

	_footstep_timer += delta
	if _footstep_timer >= footstep_interval:
		_footstep_timer = 0.0
		AudioManager.play_sfx("footstep", footstep_volume_db, 0.0)

func _turn_light_direction(is_left: bool):
	if is_left:
		flash_light.position = Vector2(-10, 10)
		flash_light.update_light_params(
			125.0,  # Range
			25.0,   # Angle (about 15 degrees each side, total ~50 degrees)
			5,
			Color(1.0, 1.0, 0.902, 0.302),
		)
	else:
		flash_light.position = Vector2(10, 10)
		flash_light.update_light_params(
			125.0,  # Range
			25.0,   # Angle (about 15 degrees each side, total ~50 degrees)
			-185,   # Direction (to the right, follows player facing)
			Color(1.0, 1.0, 0.902, 0.302),
		)

func add_health(amount: int):
	health += amount
	if health > max_health:
		health = max_health
	_update_health_bar()
	emit_signal("health_changed", health, max_health)
	Global.player_health = health

func add_speed(speed_increase: float, duration: float):
	var original_speed = speed
	speed += speed_increase
	await get_tree().create_timer(duration).timeout
	speed = original_speed

func add_invincibility(duration: float):
	is_invincible = true
	modulate.a = 0.5
	await get_tree().create_timer(duration).timeout
	is_invincible = false
	modulate.a = 1.0

func _on_jumped_on_enemy():
	# Bounce back when stepping on an enemy
	velocity.y = JUMP_VELOCITY
