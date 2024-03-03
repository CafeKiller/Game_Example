"""
@file: 角色攻击处理
@author: CoffeeKiller
@update: 2024_03_03 17:53:49
"""

class_name Hitbox
extends Area2D

## PS: 信号是 Godot 内置的一种委派机制/监听者模式

# 自定义信号, 接收一个受击体(hurtbox)
signal hit(hurtbox)

func _init() -> void:
	# area_entered 信号, 在 Area2D 发生碰撞或重叠时触发
	# 为 area_entered 信号绑定相关回调函数
	area_entered.connect(_on_area_entered)

# 碰撞/重叠处理函数, 作为 area_entered 信号的回调使用
# hurtbox 受击物体
func _on_area_entered(hurtbox: Hurtbox) -> void:
	# 打印相关日志
	print("[Hit] %s => %s" % [owner.name, hurtbox.owner.name])
	
	# 攻击信号发送给受击体, 受击体上的受击信号发送给攻击体
	# 以此完成信号的相互通信.
	hit.emit(hurtbox)
	hurtbox.hurt.emit(self)
