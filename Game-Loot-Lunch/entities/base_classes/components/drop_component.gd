extends Node
class_name DropComponent


signal item_dropped
signal drop_finished


## Scene used to instantiate Item's to be dropped.
@export var item_scene : PackedScene:
	set(value):
		if not value.instantiate() is Item:
			push_error("Item scene to instantiate drops must be Item.")
			return
		item_scene = value
@export var item_scale : Vector2 = Vector2.ONE
@export var min_amount : int = 0
@export var max_amount : int = 1
## -1 means the amount dropped any time is randomized between [min_amount] and 
## [max_amount.] Any other value implies that that exact amount is dropped
## everytime 
@export var fixed_amount : int = -1 
## Chance of dropping the item. Only relevant if fixed_amount is bigger than 0
@export_range(0.0001,1.0,0.0001) var drop_chance : float = 1


func drop_items(amount : int = fixed_amount) -> void:
	if not amount:
		return
	
	if amount < 0:
		drop_items(randi_range(min_amount,max_amount))
		return
	
	if randf() > drop_chance:
		return 
	
	var item : Item
	for i in amount:
		item = item_scene.instantiate()
		item.scale = item_scale
		item.global_position = get_parent().global_position + Vector2(randi_range(-10,10),randi_range(-10,10))
		get_tree().current_scene.call_deferred("add_child",item)
		item_dropped.emit()
	
	drop_finished.emit()
