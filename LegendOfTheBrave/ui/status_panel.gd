extends HBoxContainer

@export var stats: Stats

@onready var health_bar: TextureProgressBar = $PlayerStateBox/HealthBar
@onready var eased_health_bar: TextureProgressBar = $PlayerStateBox/HealthBar/EasedHealthBar
@onready var energy_bar: TextureProgressBar = $PlayerStateBox/EnergyBar
@onready var eased_energy_bar: TextureProgressBar = $PlayerStateBox/EnergyBar/EasedEnergyBar


func _ready() -> void:
	# 连接信号
	stats.health_changed.connect(update_health)
	stats.energy_changed.connect(update_energy)
	update_health()
	update_energy()

# 更新当前血量
func update_health() -> void:
	var percentage := stats.health / float(stats.max_health)
	health_bar.value = percentage

	create_tween().tween_property(eased_health_bar, "value", percentage, 0.3)

# 更新当前能量
func update_energy() -> void:
	var percentage := stats.energy / float(stats.max_energy)
	energy_bar.value = percentage
	
	create_tween().tween_property(eased_energy_bar, "value", percentage, 0.3)
