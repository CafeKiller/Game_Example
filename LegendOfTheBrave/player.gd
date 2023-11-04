"""
@file: 控制玩家对象
@author: CoffeeKiller
@date: 2023_11_04
"""

extends CharacterBody2D

const RUN_SPEED := 200.0
const JUMP_VELOCITY := -300.0

# 获取重力加速度 (通过项目设置获取)
var gravity := ProjectSettings.get("physics/2d/default_gravity") as float

# 获取实体
@onready var sprite_2d = $Sprite2D
@onready var animation_player = $AnimationPlayer

# 每帧物理调整
func _physics_process(delta: float) -> void:
	# 获取玩家键盘输入
	var direction := Input.get_axis("move_left", "move_right")
	
	velocity.x = direction * RUN_SPEED
	velocity.y += gravity * delta
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	
	# 检查到玩家是处于地板上的, 未处于地板上时执行跳跃动画
	if is_on_floor():
		# 检测是否有移动, 没有移动显示闲置动画, 移动了显示跑动动画
		if is_zero_approx(direction):	
			animation_player.play("idle")
		else:
			animation_player.play("running")
	else: 
		animation_player.play("jump")
		
	# 由于动画都是只展示一侧的, 需要在玩家向左移动时添加镜像反转
	if not is_zero_approx(direction):
		sprite_2d.flip_h = direction < 0
		
	move_and_slide()
	
