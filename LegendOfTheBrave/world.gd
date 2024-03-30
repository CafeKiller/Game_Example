"""
@file: 主世界相关脚本
@author: CoffeeKiller
@update: 2024_03_03 17:30:56
"""

extends Node2D

@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var tile_map: TileMap = $TileMap
@onready var player: CharacterBody2D = $Player


# 生命周期函数, 在节点加载完毕后进行调用
func _ready() -> void:
	# 获取地图内非空区域的矩形
	var used := tile_map.get_used_rect().grow(-1)
	# 获取地图内图块的大小
	var tile_size := tile_map.tile_set.tile_size
	
	# 设置镜头 防止溢出地图有效范围
	camera_2d.limit_top = used.position.y * tile_size.y
	camera_2d.limit_right = used.end.x * tile_size.x
	camera_2d.limit_bottom = used.end.y * tile_size.y
	camera_2d.limit_left = used.position.x * tile_size.x
	camera_2d.reset_smoothing()

# 更新玩家当前在地图的位置
func update_player(pos: Vector2, direction: Player.Direction) -> void:
	
	player.global_position = pos
	player.fall_from_y = pos.y
	player.direction = direction
	camera_2d.reset_smoothing() 
	# FIX: 4.2 需要额外添加: 
	# camera_2d.force_update_scroll()
