extends Node

class_name ItemDropComponent


@export var drops: Array[DropData]

var drop_count: int
var drop: Item
@onready var parent: Node2D = get_parent()


func drop_item() -> void:
	if drops.size() == 0:
		return
		
	for i in drops.size():
		if drops[i] == null:
			continue
		
		drop_count = drops[i].get_drop_count()
		for j in drop_count:
			drop = drops[i].item.instantiate() as Item
			
			parent.formigueiro.call_deferred("add_child", drop)
			drop.position = parent.position + Vector2(randf() * 64, randf() * 64)
			
