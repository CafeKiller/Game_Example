# 可交互对象类
class_name Interactable

extends Area2D

signal interacted

func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(2, true)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# 交互逻辑处理函数
func interact() -> void:
	print("[Interactable] %s" % name)
	interacted.emit()
	pass

# 进入碰撞范围内 可以进行交互
func _on_body_entered(player: Player) -> void:
	player.register_interactavle(self)
	pass
	
# 退出碰撞范围 关闭交互
func _on_body_exited(player: Player) -> void:
	player.unregister_interactavle(self)
	pass
