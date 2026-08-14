extends StaticBody2D
class_name Workbench


enum Type {None, Common, Cutter, Drying, Cooker}


signal open_inventory
signal close_inventory


@export var type : Workbench.Type


@onready var sprite: CanvasItem = $Sprite2D
@onready var interaction_component: InteractionComponent = %InteractionComponent


func _process(_delta: float) -> void:
	if GlobalData.current_workbench != type:
		return
	if Input.is_action_just_released("interact"):
		open_inventory.emit()


func _on_interactable_area_interact_with_player() -> void:
	GlobalData.current_workbench = type
	interaction_component.show_interaction()


func _on_interactable_area_stop_interact_with_player() -> void:
	if GlobalData.current_workbench == type:
		GlobalData.current_workbench = Type.None
	interaction_component.hide_interaction()
	close_inventory.emit()
