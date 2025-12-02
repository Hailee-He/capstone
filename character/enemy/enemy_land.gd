extends CharacterBody2D

# 状态枚举
enum State {
	IDLE,        # 静止
	WANDER,      # 随机游荡
	CHARGE,      # 冲锋攻击
	COOLDOWN     # 冷却中
}

# 基础参数
const WANDER_SPEED = 80.0
const CHARGE_SPEED = 400.0

# 存活和冷却参数
@export var lifetime: float = 10.0  # 存活时间（秒）
@export var attack_cooldown: float = 3.0  # 攻击后冷却时间

var current_state: State = State.WANDER
var life_timer: float = 0.0
var cooldown_timer: float = 0.0
var player: CharacterBody2D = null
var is_in_flashlight: bool = false
var player_flashlight: Light = null  # 玩家手电筒引用

# 随机游荡参数
var wander_direction: int = 1  # 1 = 右，-1 = 左
var wander_timer: float = 0.0
var idle_timer: float = 0.0
var is_wandering: bool = true

@onready var sprite: Sprite2D = $Sprite2D

var ally_detector: RayCast2D

# 预加载场景用于静态生成
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
	
	# 添加重力
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# 生命倒计时
	life_timer -= delta
	if life_timer <= 0:
		queue_free()  # 销毁自己
		return
	
	# 检测手电筒光线，优先级最高
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
	
	# 检测边缘或墙壁，转向
	if is_on_wall() or not _check_ground_ahead():
		wander_direction *= -1
		_reset_wander_timer()
	
	# 定时改变方向或停止
	if wander_timer <= 0:
		if randf() < 0.3:  # 30%概率停下来休息
			current_state = State.IDLE
			idle_timer = randf_range(1.0, 3.0)
			velocity.x = 0
		else:  # 70%概率换方向继续走
			wander_direction = 1 if randf() < 0.5 else -1
			_reset_wander_timer()
	
	# 移动
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
	
	# 如果手电筒关闭了，停止冲锋
	if not is_in_flashlight:
		current_state = State.WANDER
		return
	
	# 朝玩家冲锋（只改变X方向，保留重力影响的Y方向）
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * CHARGE_SPEED
	
	sprite.flip_h = direction.x < 0
	
	# 检测是否碰到玩家
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == player:
			_attack_player()
			return
			

func _cooldown_behavior(delta: float) -> void:
	velocity.x = 0  # 只停止水平移动
	cooldown_timer -= delta
	
	if cooldown_timer <= 0:
		current_state = State.WANDER
		_reset_wander_timer()


func _attack_player() -> void:
	if player and player.has_method("attacked"):
		player.attacked(Global.emeny_land_demage)
		
		# 击退玩家
		var knockback_direction = (player.global_position - global_position).normalized()
		var knockback_force = 100.0  # 至少100px的击退
		
		# 如果玩家有velocity属性，施加击退
		if "velocity" in player:
			player.velocity.x = knockback_direction.x * knockback_force * 10  # 乘以10增加击退速度
			player.velocity.y = -200  # 向上击飞一点
		
		# 进入冷却状态
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
	# 懒加载场景
	if enemy_scene == null:
		enemy_scene = load("res://character/enemy/emeny_land.tscn")
	
	var instance = enemy_scene.instantiate()
	instance.global_position = spawn_position
	parent.add_child(instance)
	return instance
