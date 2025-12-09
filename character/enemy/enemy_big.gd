extends CharacterBody2D
# This enemy mainly hinders the player's movement. It is large in size but moves slowly, with low damage.

@export var max_health: float = 100.0
var health: float = max_health
@export var speed: float = 25.0
@export var gravity: float = 980.0
@export var damage: int = 1

var attack_cooldown: float = 0.0

@onready var ally_detector: RayCast2D = $RayCast2D

func _ready():
	health = max_health

func _physics_process(delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta

	if velocity.x != 0:
		ally_detector.target_position.x = 60 * sign(velocity.x)
		
	if ally_detector.is_colliding():
		velocity.x = 0

	if not is_on_floor():
		velocity.y += gravity * delta

	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Only move along the X-axis
		if abs(player.global_position.x - global_position.x) > 10:
			velocity.x = sign(player.global_position.x - global_position.x) * speed
		else:
			velocity.x = 0
		
		# Flip the sprite
		if velocity.x > 0:
			if has_node("Sprite2D"):
				$Sprite2D.flip_h = false
		elif velocity.x < 0:
			if has_node("Sprite2D"):
				$Sprite2D.flip_h = true
	
	move_and_slide()

	# Collision damage logic
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player") and collider.has_method("take_damage"):
			if attack_cooldown <= 0:
				collider.take_damage(damage)
				attack_cooldown = 3.0


# Take damage
func take_damage(amount: int) -> void:
	health -= amount
	modulate = Color(1, 0.5, 0.5) # Turn red
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()

func die():
	queue_free()
