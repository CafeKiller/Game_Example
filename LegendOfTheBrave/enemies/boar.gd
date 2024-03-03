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

@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var calm_down_timer: Timer = $CalmDownTimer

# 用于处理 敌人 可以无视地形障碍物看见 玩家 的问题
func can_see_player() -> bool:
	if not player_checker.is_colliding():
		return false
	
	# BUG: 部分版本中 返回的 null 值无法转换为 bool 值, 需要手动转换
	# return player_checker.get_collider() is Player
	
	if player_checker.get_collider() is Player:
		return true
	return false

func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE, State.HURT, State.DYING:
			move(0.0, delta)
		
		State.WALK:
			move(max_speed / 3, delta)
			
		State.RUN:
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				direction *= -1
			move(max_speed, delta)
			if can_see_player():
				calm_down_timer.start()
			
## 状态切换函数
## 通过传入的 state(状态) 在内部进行判断校验再返回新的 state(状态)
func get_next_state(state: State) -> int:
	if stats.health == 0:
		return StateMachin.KEEP_CURRENT if state == State.DYING else State.DYING
		
	if pending_damage:
		return State.HURT
		
	match state:
		State.IDLE:
			if can_see_player():
				return State.RUN
			if state_machin.state_time >2:
				return State.WALK
		
		State.WALK:
			if can_see_player():
				return State.RUN
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				return State.IDLE
		
		State.RUN:
			if not can_see_player() and calm_down_timer.is_stopped():
				return State.WALK
				
		State.HURT:
			if not animation_player.is_playing():
				return State.RUN
	
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
		State.IDLE:
			animation_player.play("idle")
			if wall_checker.is_colliding():
				direction *= -1
		
		State.WALK:
			animation_player.play("walk")
			if not floor_checker.is_colliding():
				direction *= -1
				floor_checker.force_raycast_update()
			
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
	
