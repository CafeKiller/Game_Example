"""
@file: 角色受击处理
@author: CoffeeKiller
@update: 2024_03_03 17:53:49
"""

class_name Hurtbox
extends Area2D

## PS: 信号是 Godot 内置的一种委派机制/监听者模式

# 自定义信号 hurt 接收一个攻击体(hitbox)
signal hurt(hitbox)
