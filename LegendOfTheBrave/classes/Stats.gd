## file: 保存角色(包括敌人与玩家)的各种状态统计信息

class_name Stats

extends Node

@export var max_health: int = 3 # 最大血量,默认为3

@onready var health: int = max_health: # 当前血量
	set(v): 
		# 限制血量取值范围
		v = clamp(v, 0 , max_health)
		if health == v:
			return
		health = v
