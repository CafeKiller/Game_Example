extends Node

# 保存场景信息
var world_status := {
	
}

@onready var player_stats: Node = $PlayerStats
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.color.a = 0
	pass

func change_scene(path: String, entry_point: String) -> void:
	# 获取节点树
	var tree := get_tree()
	tree.paused = true
	
	# 创建补间动画
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", 1, 0.8)
	await tween.finished # 等待播放完成
	
	var old_name := tree.current_scene.scene_file_path.get_file().get_basename()
	world_status[old_name] = tree.current_scene.to_dict()

	tree.change_scene_to_file(path) # 更新场景
	# FIX: 4.2 需要修改为 tree.tree_changed
	await tree.process_frame # 等待节点完成更新 
	
	var new_name := tree.current_scene.scene_file_path.get_file().get_basename()
	if new_name in world_status:
		tree.current_scene.from_dict(world_status[new_name])
	
	# 获取节点树中的分组为 entry_point 的节点
	for node in tree.get_nodes_in_group("entry_points"):
		# 判断获取的节点名称是否与需要更新的节点名称相同
		if node.name == entry_point:
			# 更新玩家位置
			tree.current_scene.update_player(node.global_position, node.direction)
			break
	
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0, 0.8)
	
	tree.paused = false
	
	
