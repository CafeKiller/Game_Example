"""
@file: 通用状态机对象
@author: CoffeeKiller
@update: 2024_03_03 15:00:31
"""

class_name StateMachin

extends Node

# 保持状态判位符
const KEEP_CURRENT := -1

var current_state: int = -1: # 角色的当前状态
	set(v):
		# owner 指向的是除自身以外的有效父节点, 也就是该状态机的实例对象(如 player / enemy)
		# 调用实例上定义的 transition_state 函数, 进行状态的切换处理
		owner.transition_state(current_state, v)
		current_state = v
		state_time = 0 # 重置状态维持时间
		
# 状态维持时间, 记录当前状态的运行时间, 用于处理某些场景		
var state_time: float 

# 生命周期函数, 在节点加载完毕后进行调用
func _ready() -> void:
	await  owner.ready # 等待实例初始化完成
	current_state = 0 # 初始化角色状态

# 生命(回调)周期函数, 在每一个物理帧执行前都会调用, 有点类似于 unity 中的 FixedUpdate
func _physics_process(delta: float) -> void:
	while true:
		# 实时获取状态的切换, 得到最新的状态
		var next := owner.get_next_state(current_state) as int
		# 判断是否保持原状态
		if next == KEEP_CURRENT:
			break
		# 获得新状态	
		current_state = next
	
	# 调用实例上的物理帧更新函数, 完成实际的相关逻辑
	owner.tick_physics(current_state, delta)
	# 状态维持时间更新
	state_time += delta 

