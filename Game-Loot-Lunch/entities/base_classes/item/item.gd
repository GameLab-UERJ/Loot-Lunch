extends Sprite2D
class_name Item

@export var item_name : String		## Name of the Item
@export var description : String	## Description of the Item, to e shown when inspected
@export var is_ingredient : bool	## Ingredients can be used in recipees


func _ready() -> void:
	if not texture:
		push_error("Item ",item_name," must have a Texture")
