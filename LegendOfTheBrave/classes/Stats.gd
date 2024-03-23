"""
@file: 保存角色(包括敌人与玩家)的各种状态统计信息
@author: CoffeeKiller
@update: 2024_03_03 17:30:56
"""

class_name Stats

extends Node

signal health_changed
signal energy_changed

@export var max_health: int = 3 # 最大血量,默认为3
@export var max_energy: float = 10.0 # 最大能力
@export var energy_regen: float = 0.7 

@onready var health: int = max_health: # 当前血量
	set(v): 
		# 限制当前血量取值范围, 不得超过最大血量限制
		v = clampi(v, 0 , max_health)
		if health == v:
			return
		health = v
		health_changed.emit()
		
@onready var energy: float = max_energy: # 当前血量
	set(v): 
		v = clampf(v, 0 , max_energy)
		if energy == v:
			return
		energy = v
		energy_changed.emit()
		
func _process(delta: float) -> void:
	energy += energy_regen * delta
