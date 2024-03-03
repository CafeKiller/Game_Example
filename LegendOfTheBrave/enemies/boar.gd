"""
@file: 野猪角色脚本, 敌对角色
@author: CoffeeKiller
@update: 2024_03_03 18:55:22
"""

extends Enemy

enum State {
	IDLE, # 静置
	WALK, # 走动
	RUN,  # 跑动
	HIT,  # 攻击
	HURT, # 受击
	DYING,# 濒死
}

# 常量, 击退力度, 默认:512
const KNOCKBACK_AMOUNT := 512.0

# 待处理的伤害
var pending_damage: Damage

# wall_checker 墙体检测器, 用于判断前方是否存在墙壁(距离近)
@onready var wall_checker: RayCast2D = $Graphics/WallChecker
# player_checker 玩家角色检测器, 用于判断前方是否存在玩家(距离较远)
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
# floor_checker 地面检测器, 用于判断前方底部是为悬崖/段落
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
# calm_down_timer 冷静状态计时器, 
@onready var calm_down_timer: Timer = $CalmDownTimer

# can_see_player 查看玩家是否存在函数
# 主要用于处理"野猪"可以无视地形障碍物看见"玩家"的BUG
func can_see_player() -> bool:
	# 未检测到玩家
	if not player_checker.is_colliding():
		return false
	
	# BUG: Godot 部分版本中返回的 null 值自动转换为 bool 值, 需要手动转换
	# return player_checker.get_collider() is Player
	
	# FIX: 判断前方是否存在物体且还是"玩家"对象时,才触发检测
	if player_checker.get_collider() is Player:
		return true
	return false

## 物理帧处理函数, 物理帧更新时实际处理的相关逻辑
func tick_physics(state: State, delta: float) -> void:
	match state:
		# 闲置
		State.IDLE, State.HURT, State.DYING:
			move(0.0, delta)
		
		# 正常走动
		State.WALK:
			move(max_speed / 3, delta)
		
		# 冲刺跑动(狂暴)
		State.RUN:
			# 跑动时速度较快, 需要对墙面和地面进行检查, 实现快速转向
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				direction *= -1
			move(max_speed, delta)
			# 检测到玩家存在, 开启冷静计时器
			if can_see_player():
				calm_down_timer.start()
			
## 状态切换函数
## 通过传入的 state(状态) 在内部进行判断校验再返回新的 state(状态)
func get_next_state(state: State) -> int:
	# 当血量归零时
	if stats.health == 0:
		# FIX: 用于修复受击时再次受击后导致的卡死而无法进行死亡状态的BUG
		return StateMachin.KEEP_CURRENT if state == State.DYING else State.DYING
	
	# 判断是否收到伤害, 收到则直接进入受击状态	
	if pending_damage:
		return State.HURT
		
	match state:
		# 闲置
		State.IDLE:
			# 检测到玩家时进入冲刺跑动状态
			if can_see_player():
				return State.RUN
			# 检查野猪是否处于闲置状态 2 秒以上, 超 2 秒则进入走动状态
			if state_machin.state_time >2:
				return State.WALK
		
		# 正常走动
		State.WALK:
			# 检测到玩家时进入冲刺跑动状态
			if can_see_player():
				return State.RUN
			# 检测到前方为墙面/悬崖/段落时进入闲置状态
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				return State.IDLE
		
		# 冲刺跑动(狂暴)
		State.RUN:
			if not can_see_player() and calm_down_timer.is_stopped():
				return State.WALK
		
		# 受击
		State.HURT:
			# 检查受击动画是否结束, 结束后再次进入冲刺跑动状态
			if not animation_player.is_playing():
				return State.RUN
	
	# 默认返回 -1 表示还是原状态
	return StateMachin.KEEP_CURRENT
	
## 状态切换处理函数
## 负责处理状态与状态之间切换时的相关处理逻辑
## from: 原状态 to: 下一个状态
func transition_state(from: State, to: State) -> void:
	# 打印相关日志信息
	print("<Enemy.Boar> [%s] %s => %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != 1 else "<START>",
		State.keys()[to],		
	])
	
	match to:
		# 闲置
		State.IDLE:
			animation_player.play("idle")
			# 检测到前方为墙面时, 野猪则转向回身
			if wall_checker.is_colliding():
				direction *= -1
		
		# 正常走动
		State.WALK:
			animation_player.play("walk")
			# 检测到前方为悬崖/段落时, 野猪则转向回身
			if not floor_checker.is_colliding():
				direction *= -1
				# 立即更新碰撞检测
				floor_checker.force_raycast_update()
		
		# 冲刺跑动(狂暴)
		State.RUN:
			animation_player.play("run")
		
		State.HURT:
			animation_player.play("hit")
			# 角色受击,造成扣血
			stats.health -= pending_damage.amount
			
			# 获取收到伤害的受击方向向量, 并计算受击力度
			var dir := pending_damage.source.global_position.direction_to(global_position)
			velocity = dir * KNOCKBACK_AMOUNT
			
			# 根据受击方向向量的正负来让角色进行对应转向
			if dir.x > 0:
				direction = Direction.LEFT
			else:
				direction = Direction.RIGHT
			
			# 清除本次伤害
			pending_damage = null
			
		State.DYING:
			animation_player.play("die")
			

## 受击反应函数
func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	
	# Debug: 此处有一个问题, 以下的逻辑只会记录到最后一次伤害, 可以尝试使用数组进行优化
	# 创建一次伤害, 并设置此次伤害的数值量, 并绑定伤害来源
	pending_damage = Damage.new()
	pending_damage.amount = 1
	pending_damage.source = hitbox.owner
	
#	stats.health -= 1
#	# 血量归零,角色死亡,释放内存
#	if stats.health == 0:
#		# 释放对应节点的内存,以队列的形式
#		queue_free()
	
