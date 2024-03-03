"""
@file: 通用状态机对象
@author: CoffeeKiller
@update: 2024_03_03 15:00:31
"""

class_name StateMachin
extends Node

# 保持状态判位符
const KEEP_CURRENT := -1

var current_state: int = -1:
	set(v):
		owner.transition_state(current_state, v)
		current_state = v
		state_time = 0
		
var state_time: float

func _ready() -> void:
	await  owner.ready
	current_state = 0
	
func _physics_process(delta: float) -> void:
	while true:
		var next := owner.get_next_state(current_state) as int
		if next == KEEP_CURRENT:
			break
		current_state = next
		
	owner.tick_physics(current_state, delta)
	state_time += delta

