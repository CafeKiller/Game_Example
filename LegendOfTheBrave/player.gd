"""
@file: 玩家对象
@author: CoffeeKiller
@date: 2024_03_03 19:21:42
"""
class_name Player
extends CharacterBody2D

"""
@enum State 玩家状态
"""
enum State {
	IDLE, 		 # 闲置
	RUNNING, 	 # 跑动
	JUMP, 		 # 跳跃
	FALL,		 # 下落
	LANDING,	 # 着陆
	WALL_SLIDING,# 划墙下落
	WALL_JUMP,	 # 划墙跳跃
	ATTACK_1, 	 # 一段攻击
	ATTACK_2,	 # 二段攻击
	ATTACK_3,	 # 三段攻击
	HURT,		 # 受击
	DYING,		 # 濒死
	SLIDING_START, # 滑铲开始
	SLIDING_LOOP,  # 滑铲过程
	SLIDING_END,   # 滑铲结束
}

# GROUND_STATES 状态分组, 该组内的状态都是处于地面状态的
const GROUND_STATES := [
	State.IDLE, State.RUNNING, State.LANDING,
	State.ATTACK_1, State.ATTACK_2, State.ATTACK_3,
]
# 跑动时的加速度
const RUN_SPEED := 160.0 
# 处于地面时的加速度
const FLOOR_ACCELRATION := RUN_SPEED / 0.2  
# 处于浮空时的加速度
const AIR_ACCELRATION := RUN_SPEED / 0.1    
# 跳跃力度
const JUMP_VELOCITY := -300.0 
# 蹬墙跳角度
const WALL_JUMP_VELOCITY := Vector2(380, -280) 
# 常量, 击退力度, 默认:512
const KNOCKBACK_AMOUNT := 512.0
# 玩家滑铲滑动默认时间
const SLIDING_DURATION := 0.3
# 玩家滑铲时的加速度
const SLIDING_SPEED := 240.0
# 进入landing状态所需的高度
const LANDING_HEIGHT := 80.0
# 每次滑铲所需要的能量
const SLIDING_ENERGY := 4.0


# can_combo 表示玩家当前是否触发combo(连击)
@export var can_combo := false


# 获取重力加速度 (通过项目设置获取)
var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float
var is_first_tick := false # 触犯判断, 用于限制无限跳跃
var is_combo_requested := false  # 连击判断, 判断当前是否触发连击
var pending_damage: Damage # 待处理的伤害
var fall_from_y : float # 玩家掉落时的高度


# 获取实体
@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var slide_request_timer: Timer = $SlideRequestTimer
@onready var invincible_timer: Timer = $InvincibleTimer # 受击无敌时间 计时器
@onready var hand_checker: RayCast2D = $Graphics/HandChecker
@onready var foot_checker: RayCast2D = $Graphics/FootChecker
@onready var state_machin: Node = $StateMachin
@onready var stats: Node = $Stats


## 物理帧处理函数, 物理帧更新时实际处理的相关逻辑
func tick_physics(state: State, delta: float) -> void:
	
	# 处理玩家在受击无敌时间时的物理表现
	if invincible_timer.time_left > 0:
		graphics.modulate.a = sin(Time.get_ticks_msec() / 20) * 0.5 + 0.5
	else:
		graphics.modulate.a = 1
	
	match state:
		State.IDLE:
			move(default_gravity, delta)
			
		State.RUNNING:
			move(default_gravity, delta)
			
		State.JUMP:
			var temp = 0.0 if is_first_tick else default_gravity
			move(temp, delta)
			
		State.FALL:
			move(default_gravity, delta)
			
		State.LANDING:
			# move(default_gravity, delta)
			stand(default_gravity, delta)
			
		State.WALL_SLIDING:
			move(default_gravity / 2, delta)
			graphics.scale.x = get_wall_normal().x
			
		State.WALL_JUMP:
			if state_machin.state_time < 0.1 :
				var temp = 0.0 if is_first_tick else default_gravity
				stand(temp, delta)
				graphics.scale.x = get_wall_normal().x
			else:
				# var temp = 0.0 if is_first_tick else default_gravity
				move(default_gravity, delta)
				
		State.ATTACK_1, State.ATTACK_2, State.ATTACK_3:
			stand(default_gravity, delta)
			
		State.HURT, State.DYING:
			stand(default_gravity, delta)
			
		State.SLIDING_END:
			stand(default_gravity, delta)
			
		State.SLIDING_LOOP, State.SLIDING_START:
			slide(delta)
			
	is_first_tick = false
	
# 玩家移动处理函数	
func move(gravity: float, delta: float) -> void:
	# 获取玩家键盘输入
	var direction := Input.get_axis("move_left", "move_right")
	# 控制加速 地面的加速度 与 空中的加速度是不一样的.
	var acceleration := FLOOR_ACCELRATION if is_on_floor() else AIR_ACCELRATION
	# 为角色运动添加: 加速度系数
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta) 
	velocity.y += gravity * delta
			
	# 由于动画都是只展示一侧的, 需要在玩家向左移动时添加镜像反转
	if not is_zero_approx(direction):
		graphics.scale.x = -1 if direction < 0 else 1
	
	move_and_slide()
	
# 玩家站立位置处理函数	
func stand(gravity:float, delta: float) -> void:
	
	# 控制加速 地面的加速度 与 空中的加速度是不一样的.
	var acceleration := FLOOR_ACCELRATION if is_on_floor() else AIR_ACCELRATION
	# 为角色运动添加: 加速度系数
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta) 
	velocity.y += gravity * delta
	
	move_and_slide()

# 玩家滑铲处理函数
func slide(delte: float) -> void:
	velocity.x = graphics.scale.x * SLIDING_SPEED
	velocity.y += default_gravity * delte
	
	move_and_slide()

# 玩家死亡函数
func die() -> void:
	get_tree().reload_current_scene()
	
# 检测玩家输入
func _unhandled_input(event: InputEvent) -> void:
	# 为跳跃提供一个时机
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	
	# 根据空格按下的时间长短来决定跳跃的高度
	if event.is_action_released("jump") and velocity.y < JUMP_VELOCITY / 2:
		jump_request_timer.stop()
		# 判断玩家空格恢复时 高度是否达到JUMP_VELOCITY的一半, 
		# 如果没有就直接减少跳跃高度,提前结束跳跃
		if velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2 
	
	# 判断是否按下攻击并且在 combo 时机内
	if event.is_action_pressed("attack") and can_combo:
		is_combo_requested = true
	
	# 判断当前是否按下滑铲键, 并启动 滑铲定时器
	if event.is_action_pressed("slide"):
		slide_request_timer.start()
		

# func _physics_process(delta: float) -> void:
# 	# 获取玩家键盘输入
# 	var direction := Input.get_axis("move_left", "move_right")
# 	# 控制加速 地面的加速度 与 空中的加速度是不一样的.
# 	var acceleration := FLOOR_ACCELRATION if is_on_floor() else AIR_ACCELRATION
# 	# 为角色运动添加: 加速度系数
# 	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta) 
# 	velocity.y += gravity * delta
#	# 设置郊狼时间 让角色在浮空的一定时间内也可以完成跳跃操作
#		var can_jump := is_on_floor() or coyote_timer.time_left > 0
#		var should_jump := can_jump and jump_request_timer.time_left > 0
#		if should_jump:
#			velocity.y = JUMP_VELOCITY

# can_wall_slide 用于检测当前的墙面是否可以滑行
func can_wall_slide() -> bool:
	return is_on_wall() and hand_checker.is_colliding() and foot_checker.is_colliding()

# should_slide 判断玩家当前位置是否可以进行滑铲
func should_slide() -> bool:
	if slide_request_timer.is_stopped():
		return false
	if stats.energy < SLIDING_ENERGY:
		return false
	return not foot_checker.is_colliding()
	
# 切换下一个状态 (自动调用)
func get_next_state(state: State) -> int:
	
	if stats.health == 0:
		return StateMachin.KEEP_CURRENT if state == State.DYING else State.DYING
		
	if pending_damage:
		return State.HURT
	
	var can_jump := is_on_floor() or coyote_timer.time_left > 0
	var should_jump := can_jump and jump_request_timer.time_left > 0
	if should_jump:
		return State.JUMP
		
	if state in GROUND_STATES and not is_on_floor():
		return State.FALL
	
	var direction := Input.get_axis("move_left", "move_right")
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)
	
	match state:
		State.IDLE:
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK_1
			if should_slide():
				return State.SLIDING_START
			if not is_still:
				return State.RUNNING
			
		State.RUNNING:
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK_1
			if should_slide():
				return State.SLIDING_START
			if is_still:
				return State.IDLE
			
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
			
		State.FALL:
			if is_on_floor():
				var h := global_position.y - fall_from_y
				return State.LANDING if h >= LANDING_HEIGHT else State.RUNNING
			if can_wall_slide():
				return State.WALL_SLIDING
				
		State.LANDING:
			if not animation_player.is_playing():
				return State.IDLE
				
		State.WALL_SLIDING:
			if jump_request_timer.time_left > 0:
				return State.WALL_JUMP
			if is_on_floor():
				return State.IDLE
			if not is_on_wall():
				return State.FALL
		
		State.WALL_JUMP:
			if can_wall_slide() and not is_first_tick:
				return State.WALL_SLIDING
			if velocity.y >= 0:
				return State.FALL
				
		State.ATTACK_1:
			if not animation_player.is_playing():
				# 判断是否处于 combo 状态下, 如果不是则进入 IDLE 状态.
				return State.ATTACK_2 if is_combo_requested else State.IDLE
		
		State.ATTACK_2:
			if not animation_player.is_playing():
				# 判断是否处于 combo 状态下, 如果不是则进入 IDLE 状态.
				return State.ATTACK_3 if is_combo_requested else State.IDLE
				
		State.ATTACK_3:
			if not animation_player.is_playing():
				return State.IDLE
				
		State.HURT:
			if not animation_player.is_playing():
				return State.IDLE
				
		State.SLIDING_START:
			if not animation_player.is_playing():
				return State.SLIDING_LOOP
				
		State.SLIDING_END:
			if not animation_player.is_playing():
				return State.IDLE
		
		State.SLIDING_LOOP:
			if state_machin.state_time > SLIDING_DURATION or is_on_wall():
				return State.SLIDING_END
		
	
	return StateMachin.KEEP_CURRENT		

## 状态切换处理函数
## 负责处理状态与状态之间切换时的相关处理逻辑
## from: 原状态 to: 下一个状态	
func transition_state(from: State, to: State) -> void:
	
	# 打印玩家状态日志
	print("<Player> [%s] %s => %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != 1 else "<START>",
		State.keys()[to],		
	])
	
	if from not in GROUND_STATES and to in GROUND_STATES:
		coyote_timer.stop()
		
	
	match to:
		State.IDLE:
			animation_player.play("idle")
			
		State.RUNNING:
			animation_player.play("running")
			
		State.JUMP:
			animation_player.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jump_request_timer.stop()
			
		State.FALL:
			animation_player.play("fall")
			if from in GROUND_STATES:
				coyote_timer.start()
			fall_from_y = global_position.y
		
		State.LANDING:
			animation_player.play("landing")
			
		State.WALL_SLIDING:
			animation_player.play("wall_sliding")
			
		State.WALL_JUMP:
			animation_player.play("jump")
			velocity = WALL_JUMP_VELOCITY
			velocity.x *= get_wall_normal().x
			jump_request_timer.stop()
			
		State.ATTACK_1:
			animation_player.play("attack_1")
			is_combo_requested = false
			
		State.ATTACK_2:
			animation_player.play("attack_2")
			is_combo_requested = false
			
		State.ATTACK_3:
			animation_player.play("attack_3")
			is_combo_requested = false
			
		State.HURT:
			animation_player.play("hurt")
			# 角色受击,造成扣血
			stats.health -= pending_damage.amount
			
			# 获取收到伤害的受击方向向量, 并计算受击力度
			var dir := pending_damage.source.global_position.direction_to(global_position)
			velocity = dir * KNOCKBACK_AMOUNT
			
			# 清除本次伤害
			pending_damage = null
			# 开启受击后无敌
			invincible_timer.start()
			
		State.DYING:
			animation_player.play("die")
			# 死亡时不需要无敌时间了
			invincible_timer.stop()
			
		State.SLIDING_START:
			animation_player.play("sliding_start")
			slide_request_timer.stop()
			stats.energy -= SLIDING_ENERGY
			
		State.SLIDING_LOOP:
			animation_player.play("sliding_loop")
			
		State.SLIDING_END:
			animation_player.play("sliding_end")
		


			
#	if to == State.WALL_JUMP:
#		Engine.time_scale = 0.3
#	if from == State.WALL_JUMP:
#		Engine.time_scale = 1
				
	is_first_tick = true

## 受击反应函数
func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	# 处理受击无敌时间, 在无敌时间内不会再受击
	if invincible_timer.time_left > 0:
		return

	# Debug: 此处有一个问题, 以下的逻辑只会记录到最后一次伤害, 可以尝试使用数组进行优化
	# 创建一次伤害, 并设置此次伤害的数值量, 并绑定伤害来源
	pending_damage = Damage.new()
	pending_damage.amount = 1
	pending_damage.source = hitbox.owner
