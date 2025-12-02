extends Area2D
class_name Light

# 扇形光线的参数
@export var light_range: float = 300.0  # 光线范围（半径）
@export var light_angle: float = 90.0   # 扇形的角度（度数，总角度）
@export var light_direction: float = 0.0  # 光线方向（度数，0为右，-90为上）
@export var light_color: Color = Color(1, 0.9, 0.7, 1)  # 光线颜色

# 碰撞检测
var bodies_in_light: Array = []
var collision_polygon: CollisionPolygon2D

func _ready() -> void:
	# 创建扇形碰撞区域
	_create_fan_collision()
	
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _create_fan_collision() -> void:
	if collision_polygon:
		collision_polygon.queue_free()
	
	collision_polygon = CollisionPolygon2D.new()
	add_child(collision_polygon)
	
	# 生成扇形多边形顶点
	var points: PackedVector2Array = []
	points.append(Vector2.ZERO)  # 扇形的圆心
	
	# 计算扇形的顶点数量（根据角度）
	var segments = max(8, int(light_angle / 10.0))
	var start_angle = deg_to_rad(light_direction - light_angle / 2.0)
	var end_angle = deg_to_rad(light_direction + light_angle / 2.0)
	
	for i in range(segments + 1):
		var angle = start_angle + (end_angle - start_angle) * i / segments
		var point = Vector2(cos(angle), sin(angle)) * light_range
		points.append(point)
	
	collision_polygon.polygon = points

# 物体进入光线
func _on_body_entered(body: Node2D) -> void:
	if body not in bodies_in_light:
		bodies_in_light.append(body)

func _on_body_exited(body: Node2D) -> void:
	if body in bodies_in_light:
		bodies_in_light.erase(body)

# 区域进入光线
func _on_area_entered(area: Area2D) -> void:
	if area != self and area not in bodies_in_light:
		bodies_in_light.append(area)

func _on_area_exited(area: Area2D) -> void:
	if area in bodies_in_light:
		bodies_in_light.erase(area)

# 获取在光线范围内的所有物体
func get_bodies_in_light() -> Array:
	return bodies_in_light.duplicate()

# 检查物体是否在光线内
func is_in_light(node: Node2D) -> bool:
	return node in bodies_in_light

# 更新光线参数（用于动态调整）
func update_light_params(new_range: float = -1, new_angle: float = -1, new_direction: float = -999, new_color: Color = Color.WHITE) -> void:
	if new_range > 0:
		light_range = new_range
	if new_angle > 0:
		light_angle = new_angle
	if new_direction > -999:
		light_direction = new_direction
	if new_color != Color.WHITE:
		light_color = new_color
	_create_fan_collision()
	queue_redraw()

# 绘制扇形光线
func _draw() -> void:
	var start_angle = deg_to_rad(light_direction - light_angle / 2.0)
	var end_angle = deg_to_rad(light_direction + light_angle / 2.0)
	
	# 生成扇形多边形顶点用于填充
	var segments = max(16, int(light_angle / 5.0))
	var points: PackedVector2Array = []
	points.append(Vector2.ZERO)  # 扇形圆心
	
	for i in range(segments + 1):
		var angle = start_angle + (end_angle - start_angle) * i / segments
		var point = Vector2(cos(angle), sin(angle)) * light_range
		points.append(point)
	
	# 绘制填充的扇形（带渐变效果）
	var gradient_steps = 100
	for i in range(gradient_steps):
		var ratio = float(i) / float(gradient_steps)
		var current_range = light_range * (1.0 - ratio)
		var current_alpha = (1.0 - ratio) * light_color.a * 0.05  # 调整透明度
		var current_color = Color(light_color.r, light_color.g, light_color.b, current_alpha)
		
		var gradient_points: PackedVector2Array = []
		gradient_points.append(Vector2.ZERO)
		
		for j in range(segments + 1):
			var angle = start_angle + (end_angle - start_angle) * j / segments
			var point = Vector2(cos(angle), sin(angle)) * current_range
			gradient_points.append(point)
		
		draw_colored_polygon(gradient_points, current_color)
	
	## 绘制扇形边缘轮廓（调试用）
	#if Engine.is_editor_hint() or OS.is_debug_build():
		#draw_arc(Vector2.ZERO, light_range, start_angle, end_angle, 32, light_color, 2.0)
		#
		#var start_point = Vector2(cos(start_angle), sin(start_angle)) * light_range
		#var end_point = Vector2(cos(end_angle), sin(end_angle)) * light_range
		#draw_line(Vector2.ZERO, start_point, light_color, 2.0)
		#draw_line(Vector2.ZERO, end_point, light_color, 2.0)

func _process(delta: float) -> void:
	queue_redraw()  # 持续重绘以显示光线范围
	
	# 对光照范围内的物体施加影响
	for body in bodies_in_light:
		if body.has_method("on_light_exposure"):
			body.on_light_exposure(delta)
