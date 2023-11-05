"""
@file: 控制玩家对象
@author: CoffeeKiller
@date: 2023_11_04
"""

extends CharacterBody2D

const RUN_SPEED := 160.0
const FLOOR_ACCELRATION := RUN_SPEED / 0.2 	# 处于地面时的加速度
const AIR_ACCELRATION := RUN_SPEED / 0.02 	# 处于浮空时的加速度
const JUMP_VELOCITY := -300.0				

# 获取重力加速度 (通过项目设置获取)
var gravity := ProjectSettings.get("physics/2d/default_gravity") as float

# 获取实体
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer

# 检测玩家输入
func _unhandled_input(event: InputEvent) -> void:
	# 为跳跃提供一个时机
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	
	# 根据空格按下的时间长短来决定跳跃的高度
	if event.is_action_released("jump") and velocity.y < JUMP_VELOCITY / 2:
		# 判断玩家空格恢复时 高度是否达到JUMP_VELOCITY的一半, 
		# 如果没有就直接减少跳跃高度,提前结束跳跃
		velocity.y = JUMP_VELOCITY / 2


# 每帧物理调整
func _physics_process(delta: float) -> void:
	# 获取玩家键盘输入
	var direction := Input.get_axis("move_left", "move_right")
	# 控制加速 地面的加速度 与 空中的加速度是不一样的.
	var acceleration := FLOOR_ACCELRATION if is_on_floor() else AIR_ACCELRATION
	# 为角色运动添加: 加速度系数
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta) 
	velocity.y += gravity * delta
	
	# 设置郊狼时间 让角色在浮空的一定时间内也可以完成跳跃操作
	var can_jump := is_on_floor() or coyote_timer.time_left > 0
	var should_jump := can_jump and jump_request_timer.time_left > 0
	if should_jump:
		velocity.y = JUMP_VELOCITY
		coyote_timer.stop()
		jump_request_timer.stop()
	
	# 检查到玩家是处于地板上的, 未处于地板上时执行跳跃动画
	if is_on_floor():
		# 检测是否有移动, 没有移动显示闲置动画, 移动了显示跑动动画
		if is_zero_approx(direction) and is_zero_approx(velocity.x):	
			animation_player.play("idle")
		else:
			animation_player.play("running")
	else: 
		animation_player.play("jump")
		
	# 由于动画都是只展示一侧的, 需要在玩家向左移动时添加镜像反转
	if not is_zero_approx(direction):
		sprite_2d.flip_h = direction < 0
		
	# 获取角色当前是否处于地面中
	var was_on_floor := is_on_floor()
	
	move_and_slide()
	
	# 在此处判断角色的运动状态是否有变化(离开地面)
	if is_on_floor() != was_on_floor:
		# 如果角色的运动状态变化(也就是说离开地面了), 
		# 并且不处于跳跃状态, 那么就开启'郊狼时间'
		if was_on_floor and not should_jump:
			coyote_timer.start()
		else: 
			coyote_timer.stop()	
