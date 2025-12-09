extends CharacterBody2D
# This enemy has low health, moves quickly, and takes damage when exposed to light.

@export var max_health: float = 20.0
var health: float = max_health
@export var speed: float = 150.0
@export var gravity: float = 980.0
@export var damage: int = 2
var attack_cooldown: float = 1.0


func _ready():
	health = max_health

func _physics_process(delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta

	if not is_on_floor():
		velocity.y += gravity * delta

	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Only move if the player is far enough on the X-axis
		if abs(player.global_position.x - global_position.x) > 10:
			velocity.x = sign(player.global_position.x - global_position.x) * speed
		else:
			velocity.x = 0
		
		# Flip the sprite based on movement direction
		if velocity.x > 0:
			if has_node("Sprite2D"):
				$Sprite2D.flip_h = false
		elif velocity.x < 0:
			if has_node("Sprite2D"):
				$Sprite2D.flip_h = true
	
	move_and_slide()
	
	# Check for collisions with the player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			# Check if the player is jumping onto the enemy from above
			if collision.get_normal().y < -0.5:  # Collision normal is pointing upwards, meaning the player is jumping from above
				take_damage(10.0)  # Take damage when stepped on
				# Make the player bounce off
				if collider.has_method("_on_jumped_on_enemy"):
					collider._on_jumped_on_enemy()
			elif collider.has_method("take_damage"):
				# Side collision causes damage
				if attack_cooldown <= 0:
					collider.take_damage(damage)
					attack_cooldown = 1.0


func on_light_exposure(delta: float) -> void:
	# Take damage from light exposure
	take_damage(20.0 * delta)  # Light damage

func take_damage(amount: float) -> void:
	health -= amount
	modulate = Color(1, 0.5, 0.5)  # Change color to red when hurt
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)  # Reset color back to normal
	
	if health <= 0:
		die()

func die():
	queue_free()  # Remove the enemy from the scene when it dies
