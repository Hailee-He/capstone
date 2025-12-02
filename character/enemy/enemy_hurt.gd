extends CharacterBody2D
# 这个敌人主要是血量较少，移动较快，受到光会掉血

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
		if abs(player.global_position.x - global_position.x) > 10:
			velocity.x = sign(player.global_position.x - global_position.x) * speed
		else:
			velocity.x = 0
		
		if velocity.x > 0:
			if has_node("Sprite2D"):
				$Sprite2D.flip_h = false
		elif velocity.x < 0:
			if has_node("Sprite2D"):
				$Sprite2D.flip_h = true
	
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			# 检测玩家是否从上方踩到敌人
			if collision.get_normal().y < -0.5:  # 碰撞法线向上，说明玩家从上方踩下
				take_damage(10.0)  # 被踩到时受伤
				# 让玩家反弹
				if collider.has_method("_on_jumped_on_enemy"):
					collider._on_jumped_on_enemy()
			elif collider.has_method("take_damage"):
				# 侧面碰撞才造成伤害
				if attack_cooldown <= 0:
					collider.take_damage(damage)
					attack_cooldown = 1.0


func on_light_exposure(delta: float) -> void:
	take_damage(20.0 * delta) # 光照伤害


func take_damage(amount: float) -> void:
	health -= amount
	modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()


func die():
	queue_free()
