extends CharacterBody2D

# State enumeration
enum State {
	PATROL,      # Patrolling
	CHASE,       # Chasing the player
	FLEE         # Fleeing from the light
}

# Basic parameters
const PATROL_SPEED = 50.0
const CHASE_SPEED = 150.0
const FLEE_SPEED = 200.0

# Patrolling parameters
@export var patrol_left: float = -100.0
@export var patrol_right: float = 100.0

# Detection parameters
@export var detect_range: float = 300.0

var current_state: State = State.PATROL
var patrol_direction: int = 1
var start_position: Vector2
var player: CharacterBody2D = null
var flee_timer: float = 0.0
var flee_cooldown: float = 4.0
var attack_flee_cooldown: float = 3.0
var is_in_light: bool = false
var is_returning: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# Store the initial position of the enemy
	start_position = global_position


func _physics_process(delta: float) -> void:
	# If the enemy is returning to the starting position
	if is_returning:
		_return_to_start(delta)
	else:
		match current_state:
			State.PATROL:
				_patrol(delta)
			State.CHASE:
				_chase_player(delta)
			State.FLEE:
				_flee_from_player(delta)
	
	move_and_slide()


func _patrol(_delta: float) -> void:
	# Calculate the target patrol position
	var target_x = start_position.x + (patrol_right if patrol_direction > 0 else patrol_left)
	
	# Change direction when reaching the patrol boundary
	if (patrol_direction > 0 and global_position.x >= target_x) or \
	   (patrol_direction < 0 and global_position.x <= target_x):
		patrol_direction *= -1
	
	velocity.x = patrol_direction * PATROL_SPEED
	velocity.y = 0
	
	# Flip the sprite depending on direction
	sprite.flip_h = patrol_direction < 0
	
	# Detect the player
	_detect_player()


func _chase_player(_delta: float) -> void:
	if not player:
		current_state = State.PATROL
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * CHASE_SPEED
	
	# Flip the sprite depending on player direction
	sprite.flip_h = direction.x < 0

	# Check for collision with the player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == player:
			_attack_player()


func _flee_from_player(delta: float) -> void:
	# Update the flee timer
	flee_timer -= delta
	
	if flee_timer <= 0:
		# After cooldown, check if the enemy can still see the player
		if _can_see_player():
			current_state = State.CHASE
		else:
			# Start returning to the starting position
			is_returning = true
		return
	
	if player:
		var direction = (global_position - player.global_position).normalized()
		velocity = direction * FLEE_SPEED
		sprite.flip_h = direction.x < 0


func _detect_player() -> void:
	# Detect the player if not already assigned
	if not player:
		_find_player()
		return
	
	# Switch to chase state if the player is detected
	if _can_see_player():
		current_state = State.CHASE

# Find the player in the scene
func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

# Check if the enemy can see the player
func _can_see_player() -> bool:
	if not player:
		return false
	
	var distance = global_position.distance_to(player.global_position)
	return distance <= detect_range


func _attack_player() -> void:
	# Attack the player and apply damage
	if player and player.has_method("attacked"):
		player.attacked(Global.emeny_fly_demage)
		current_state = State.FLEE
		flee_timer = attack_flee_cooldown
		# Add random deviation to the fleeing direction
		var random_angle = randf_range(-PI/3, PI/3)  # ±90 degrees random offset
		var base_direction = (global_position - player.global_position).normalized()
		var rotated_direction = base_direction.rotated(random_angle)
		velocity = rotated_direction * FLEE_SPEED


func _return_to_start(_delta: float) -> void:
	# While returning, also check for the player
	if _can_see_player():
		is_returning = false
		current_state = State.CHASE
		return
	
	var direction = (start_position - global_position).normalized()
	var distance = global_position.distance_to(start_position)
	
	# Switch to patrol state when close to the starting position
	if distance < 10.0:
		global_position = start_position
		is_returning = false
		current_state = State.PATROL
		return
	
	velocity = direction * PATROL_SPEED
	sprite.flip_h = direction.x < 0


# When the enemy is hit by the light (triggered by Light node or Area2D detection)
func _on_light_entered() -> void:
	# Switch to flee state when detected by light
	if current_state != State.FLEE:
		current_state = State.FLEE
		flee_timer = flee_cooldown
		is_in_light = true


func _on_light_exited() -> void:
	# Light has exited, stop fleeing
	is_in_light = false


# Light detection area signal
func _on_light_detector_area_entered(area: Area2D) -> void:
	# Check if it's a Light type
	if area is Light:
		_on_light_entered()


func _on_light_detector_area_exited(area: Area2D) -> void:
	if area is Light:
		_on_light_exited()
