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
## -1 means the amount dropped any time is randomized between [min_amount] and 
## [max_amount.] Any other value implies that that exact amount is dropped
## everytime 
@export var fixed_amount : int = -1 
@export var min_amount : int = 0
@export var max_amount : int = 1


func drop_items(amount : int = fixed_amount) -> void:
	if not amount:
		return
	
	if amount < 0:
		drop_items(randi_range(min_amount,max_amount))
		return
	
	var item : Item
	for i in amount:
		item = item_scene.instantiate()
		item.global_position = get_parent().global_position + Vector2(randi_range(-50,50),randi_range(-50,50))
		get_tree().current_scene.call_deferred("add_child",item)
		item_dropped.emit()
	
	drop_finished.emit()
