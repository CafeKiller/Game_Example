extends Node

@onready var player_stats: Node = $PlayerStats

func change_scene(path: String, entry_point: String) -> void:
	# 获取节点树
	var tree := get_tree()

	tree.change_scene_to_file(path) # 更新场景
	# FIX: 4.2 需要修改为 tree.tree_changed
	await tree.process_frame # 等待节点完成更新 
	
	# 获取节点树中的分组为 entry_point 的节点
	for node in tree.get_nodes_in_group("entry_points"):
		# 判断获取的节点名称是否与需要更新的节点名称相同
		if node.name == entry_point:
			# 更新玩家位置
			tree.current_scene.update_player(node.global_position, node.direction)
			break
	
	
	
	
