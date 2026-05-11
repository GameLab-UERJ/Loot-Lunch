extends Control
class_name Item

@export var item_name : String		## Name of the Item
@export var description : String	## Description of the Item, to e shown when inspected
@export var is_ingredient : bool	## Ingredients can be used in recipees


var sprite : Sprite2D


func _ready() -> void:
	for node in get_children():
		if node is Sprite2D:
			sprite = node
			break
	if not sprite:
		push_error("Item ",item_name," must have a Sprite2D as child")
