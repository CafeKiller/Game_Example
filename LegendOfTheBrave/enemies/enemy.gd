"""
@file: 通用敌对角色
@author: CoffeeKiller
@update: 2024_03_03 18:14:56
"""

class_name Enemy
extends CharacterBody2D

# Direction 枚举 角色二维平面 X 轴朝向
enum Direction {
	LEFT = -1,
	RIGHT = +1,
}

# 当前角色的二维平面 X 轴朝向
@export var direction := Direction.LEFT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		graphics.scale.x = -direction
@export var max_speed: float = 180 		# 最大的移动速度
@export var acceleration: float = 2000	# 冲刺状态的加速度

# 默认重力, 通过项目的配置文件获取
var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machin: Node = $StateMachin
@onready var stats: Node = $Stats

# 角色移动处理函数
func move(speed: float, delta: float) -> void:
	# move_toward 内置位置移动函数
	velocity.x = move_toward(velocity.x, speed * direction, acceleration * delta)
	velocity.y += default_gravity * delta
	
	# move_and_slide 内置函数, 会进行碰撞校验以及对应处理
	move_and_slide()

# 角色死亡处理函数
func die() -> void:
	# queue_free 内置函数, 释放对应节点的相关内存, 以队列的形式处理
	queue_free()

