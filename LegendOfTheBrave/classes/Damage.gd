## file: 伤害计算,主要负责统计角色之间的伤寒计算以及伤害构成, 及其相关处理逻辑.

class_name Damage
extends RefCounted

var amount:int # 当次伤害的数值量

var source: Node2D # 伤害源
