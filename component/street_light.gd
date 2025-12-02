extends Node2D

@onready var light_scene_l: Light = $lightSceneL
@onready var light_scene_r: Light = $lightSceneR

func _ready() -> void:
	# 配置路灯光线参数
	# 路灯向下照射，角度较大
	light_scene_l.update_light_params(
		255.0,  # 范围
		21.0,  # 角度
		90.0,   # 方向（向下）
		Color(0.631, 0.631, 0.533, 0.192)  # 光线颜色
	)
	
	light_scene_r.update_light_params(
		255.0,  # 范围
		21,  # 角度
		90.0,   # 方向（向下）
		Color(0.631, 0.631, 0.533, 0.192)  # 光线颜色
	)


func _process(_delta: float) -> void:
	var bodies = light_scene_l.get_bodies_in_light()
	if bodies.size() > 0:
		for body in bodies:
			if body.has_method("on_illuminated"):
				body.on_illuminated()
