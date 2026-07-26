extends StaticBody2D
class_name Workbench


enum Type {None, Common, Cutter, Drying, Cooker}


@export var type : Workbench.Type
@export var outline_width : int = 1


@onready var sprite: CanvasItem = $Sprite2D


func _on_interactable_area_interact_with_player() -> void:
	GlobalData.current_workbench = type
	sprite.material.set("shader_parameter/width",outline_width)
	print(name)


func _on_interactable_area_stop_interact_with_player() -> void:
	if GlobalData.current_workbench == type:
		GlobalData.current_workbench = Type.None
	sprite.material.set("shader_parameter/width",0)
