extends CharacterBody2D

# State enumeration
enum State {
	IDLE,        # Idle
	WANDER,      # Wandering randomly
	CHARGE,      # Charge attack
	COOLDOWN     # Cooling down
}

# Basic parameters
const WANDER_SPEED = 80.0
const CHARGE_SPEED = 400.0

# Lifespan and cooldown parameters
@export var lifetime: float = 10.0  # Lifespan (in seconds)
@export var attack_cooldown: float = 3.0  # Cooldown time after attack

var current_state: State = State.WANDER
var life_timer: float = 0.0
var cooldown_timer: float = 0.0
var player: CharacterBody2D = null
var is_in_flashlight: bool = false
var player_flashlight: Light = null  # Reference to the player's flashlight

# Wandering parameters
var wander_direction: int = 1  # 1 = Right, -1 = Left
var wander_timer: float = 0.0
var idle_timer: float = 0.0
var is_wandering: bool = true

@onready var sprite: Sprite2D = $Sprite2D

var ally_detector: RayCast2D

# Preload scene for static generation
static var enemy_scene: PackedScene = null

func _ready() -> void:
	add_to_group("enemy")
	
	# Configure collision layers
	collision_layer = 4  # Layer 3: enemy_basic
	collision_mask = 7   # Layers 1 (world), 2 (player), 3 (enemy_basic)
	
	# Setup Ally Detector
	ally_detector = RayCast2D.new()
	ally_detector.target_position = Vector2(50, 0)
	ally_detector.collision_mask = 4 # Detect other enemy_basic
	add_child(ally_detector)
	
	life_timer = lifetime
	_find_player()
	_find_player_flashlight()
	_reset_wander_timer()

func _physics_process(delta: float) -> void:
	# Update detector direction
	if velocity.x != 0:
		ally_detector.target_position.x = 50 * sign(velocity.x)
		
	# Stop if ally in front (unless charging)
	if current_state != State.CHARGE and ally_detector.is_colliding():
		velocity.x = 0
	
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Life countdown
	life_timer -= delta
	if life_timer <= 0:
		queue_free()  # Destroy itself
		return
	
	# Check flashlight exposure, highest priority
	if is_in_flashlight and current_state != State.CHARGE and current_state != State.COOLDOWN:
		current_state = State.CHARGE
	
	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.WANDER:
			_wander_behavior(delta)
		State.CHARGE:
			_charge_at_player(delta)
		State.COOLDOWN:
			_cooldown_behavior(delta)
	
	move_and_slide()


func _idle_behavior(delta: float) -> void:
	velocity.x = 0
	
	idle_timer -= delta
	if idle_timer <= 0:
		current_state = State.WANDER
		_reset_wander_timer()


func _wander_behavior(delta: float) -> void:
	wander_timer -= delta
	
	# Check edges or walls and turn around
	if is_on_wall() or not _check_ground_ahead():
		wander_direction *= -1
		_reset_wander_timer()
	
	# Change direction or stop after a random time
	if wander_timer <= 0:
		if randf() < 0.3:  # 30% chance to stop and rest
			current_state = State.IDLE
			idle_timer = randf_range(1.0, 3.0)
			velocity.x = 0
		else:  # 70% chance to change direction and continue
			wander_direction = 1 if randf() < 0.5 else -1
			_reset_wander_timer()
	
	# Move
	velocity.x = wander_direction * WANDER_SPEED
	sprite.flip_h = wander_direction < 0


func _check_ground_ahead() -> bool:
	var check_distance = 20.0
	var check_position = global_position + Vector2(wander_direction * check_distance, 30)
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, check_position)
	var result = space_state.intersect_ray(query)
	
	return result.size() > 0


func _reset_wander_timer() -> void:
	wander_timer = randf_range(2.0, 5.0)


func _charge_at_player(_delta: float) -> void:
	if not player:
		current_state = State.WANDER
		return
	
	# Stop charging if the flashlight is off
	if not is_in_flashlight:
		current_state = State.WANDER
		return
	
	# Charge towards the player (only change X direction, retain gravity's effect on Y)
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * CHARGE_SPEED
	
	sprite.flip_h = direction.x < 0
	
	# Check if collided with the player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == player:
			_attack_player()
			return
			

func _cooldown_behavior(delta: float) -> void:
	velocity.x = 0  # Stop horizontal movement
	cooldown_timer -= delta
	
	if cooldown_timer <= 0:
		current_state = State.WANDER
		_reset_wander_timer()


func _attack_player() -> void:
	if player and player.has_method("attacked"):
		player.attacked(Global.emeny_land_demage)
		
		# Knockback the player
		var knockback_direction = (player.global_position - global_position).normalized()
		var knockback_force = 100.0  # Knockback by at least 100px
		
		# If the player has velocity, apply knockback
		if "velocity" in player:
			player.velocity.x = knockback_direction.x * knockback_force * 10  # Multiply by 10 for stronger knockback
			player.velocity.y = -200  # Knock the player up a little
		
		# Enter cooldown state
		current_state = State.COOLDOWN
		cooldown_timer = attack_cooldown


func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func _find_player_flashlight() -> void:
	if player and player.has_node("FlashLight"):
		player_flashlight = player.get_node("FlashLight")


func _on_light_detector_area_entered(area: Area2D) -> void:
	if area is Light and area == player_flashlight:
		is_in_flashlight = true


func _on_light_detector_area_exited(area: Area2D) -> void:
	if area is Light and area == player_flashlight:
		is_in_flashlight = false


static func spawn_at(spawn_position: Vector2, parent: Node) -> CharacterBody2D:
	# Lazy load the scene
	if enemy_scene == null:
		enemy_scene = load("res://character/enemy/emeny_land.tscn")
	
	var instance = enemy_scene.instantiate()
	instance.global_position = spawn_position
	parent.add_child(instance)
	return instance
