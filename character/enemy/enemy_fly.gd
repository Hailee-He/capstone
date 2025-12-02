extends CharacterBody2D


# 状态枚举
enum State {
	PATROL,      # 巡逻
	CHASE,       # 追击玩家
	FLEE         # 逃离光线
}

# 基础参数
const PATROL_SPEED = 50.0
const CHASE_SPEED = 150.0
const FLEE_SPEED = 200.0


# 巡逻参数
@export var patrol_left: float = -100.0
@export var patrol_right: float = 100.0

# 检测参数
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
	start_position = global_position


func _physics_process(delta: float) -> void:
	# 如果正在返回起点
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
	var target_x = start_position.x + (patrol_right if patrol_direction > 0 else patrol_left)
	
	# 到达边界时转向
	if (patrol_direction > 0 and global_position.x >= target_x) or \
	   (patrol_direction < 0 and global_position.x <= target_x):
		patrol_direction *= -1
	
	velocity.x = patrol_direction * PATROL_SPEED
	velocity.y = 0
	
	sprite.flip_h = patrol_direction < 0
	
	# 检测玩家
	_detect_player()


func _chase_player(_delta: float) -> void:
	if not player:
		current_state = State.PATROL
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * CHASE_SPEED
	
	sprite.flip_h = direction.x < 0

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == player:
			_attack_player()


func _flee_from_player(delta: float) -> void:
	flee_timer -= delta
	
	if flee_timer <= 0:
		# 冷却时间结束后检查是否还能看到玩家
		if _can_see_player():
			current_state = State.CHASE
		else:
			# 飞回起始位置
			is_returning = true
		return
	
	if player:
		var direction = (global_position - player.global_position).normalized()
		velocity = direction * FLEE_SPEED
		sprite.flip_h = direction.x < 0


func _detect_player() -> void:
	if not player:
		_find_player()
		return
	
	if _can_see_player():
		current_state = State.CHASE

# 查找玩家
func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

# 检查是否能看到玩家
func _can_see_player() -> bool:
	if not player:
		return false
	
	var distance = global_position.distance_to(player.global_position)
	return distance <= detect_range


func _attack_player() -> void:
	if player and player.has_method("attacked"):
		player.attacked( Global.emeny_fly_demage)
		current_state = State.FLEE
		flee_timer = attack_flee_cooldown
		# 添加随机偏移逃离方向
		var random_angle = randf_range(-PI/3, PI/3)  # ±90度随机偏移
		var base_direction = (global_position - player.global_position).normalized()
		var rotated_direction = base_direction.rotated(random_angle)
		velocity = rotated_direction * FLEE_SPEED


func _return_to_start(_delta: float) -> void:
	# 返回途中也检测玩家
	if _can_see_player():
		is_returning = false
		current_state = State.CHASE
		return
	
	var direction = (start_position - global_position).normalized()
	var distance = global_position.distance_to(start_position)
	
	# 接近起点时切换回巡逻
	if distance < 10.0:
		global_position = start_position
		is_returning = false
		current_state = State.PATROL
		return
	
	velocity = direction * PATROL_SPEED
	sprite.flip_h = direction.x < 0


# 被光线照到（由 Light 节点调用或通过 Area2D 检测）
func _on_light_entered() -> void:
	if current_state != State.FLEE:
		current_state = State.FLEE
		flee_timer = flee_cooldown
		is_in_light = true


func _on_light_exited() -> void:
	is_in_light = false


# 光线检测器信号
func _on_light_detector_area_entered(area: Area2D) -> void:
	# 检查是否是 Light 类型
	if area is Light:
		_on_light_entered()


func _on_light_detector_area_exited(area: Area2D) -> void:
	if area is Light:
		_on_light_exited()
