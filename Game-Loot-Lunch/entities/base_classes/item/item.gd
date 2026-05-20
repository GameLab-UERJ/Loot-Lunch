extends Sprite2D
class_name Item

const CLICKABLE_AREA = preload("uid://ckaqkpas3ttwr")


@export var item_name : String		## Name of the Item
@export var description : String	## Description of the Item, to e shown when inspected
@export var is_ingredient : bool	## Ingredients can be used in recipees


@onready var clickable_area: ClickableArea = get_node("ClickableArea") if has_node("ClickableArea") else null


func _ready() -> void:
	if not texture:
		push_error("Item ",item_name," must have a Texture")
	if not clickable_area:
		clickable_area = CLICKABLE_AREA.instantiate()
		add_child(clickable_area)


func _process(_delta: float) -> void:
	if clickable_area.is_following_mouse:
		global_position = get_global_mouse_position()
