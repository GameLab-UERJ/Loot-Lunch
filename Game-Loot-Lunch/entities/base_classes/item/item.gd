extends Sprite2D
class_name Item

const CLICKABLE_AREA = preload("uid://ckaqkpas3ttwr")
const INTERACTABLE_AREA = preload("uid://cbs8q2hki4fym")


signal picked_up(item : Item)


@export var item_name : String		## Name of the Item
@export var description : String	## Description of the Item, to e shown when inspected
@export var is_ingredient : bool	## Ingredients can be used in recipees
## Quantas unidades este Item representa quando dropado no mundo.
## Default 1; para stacks, pode ser > 1.
var dropped_count: int = 1


@onready var clickable_area: ClickableArea = get_node("ClickableArea") if has_node("ClickableArea") else null
@onready var interactable_area: InteractableArea = get_node("InteractableArea") if has_node("InteractableArea") else null


func _ready() -> void:
	if not texture:
		push_error("Item ",item_name," must have a Texture")
	if not clickable_area:
		clickable_area = CLICKABLE_AREA.instantiate()
		call_deferred("add_child",clickable_area)
	if not interactable_area:
		interactable_area = INTERACTABLE_AREA.instantiate()
		call_deferred("add_child",interactable_area)
	interactable_area.interact_with_player.connect(emit_picked_up)


func _process(_delta: float) -> void:
	if clickable_area.is_following_mouse:
		global_position = get_global_mouse_position()


func emit_picked_up() -> void:
	picked_up.emit(self)


func force_follow_mouse() -> void:
	if not clickable_area:
		return
	clickable_area.is_following_mouse = true


func force_stop_follow_mouse() -> void:
	if not clickable_area:
		return
	clickable_area.is_following_mouse = false
