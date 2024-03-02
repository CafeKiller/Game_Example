# 攻击框
class_name Hitbox
extends Area2D

# 信号, 接收一个 hurtbox
signal hit(hurtbox)

func _init() -> void:
	# 为 area_entered 绑定信号触发时的回调
	area_entered.connect(_on_area_entered)

# 触发进入函数, 当另一个 area2d 进入时会触发
func _on_area_entered(hurtbox: Hurtbox) -> void:
	print("[Hit] %s => %s" % [owner.name, hurtbox.owner.name])
	
	# 发送信号
	hit.emit(hurtbox)
	
	hurtbox.hurt.emit(self)
