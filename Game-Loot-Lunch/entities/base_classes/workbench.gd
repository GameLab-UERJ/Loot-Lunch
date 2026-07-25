extends StaticBody2D
class_name Workbench


enum Type {None, Common, Cutter, Spit, Cooker}


@export var type : Workbench.Type


@onready var sprite: Sprite2D = $Sprite2D


func _on_interactable_area_interact_with_player() -> void:
	GlobalData.current_workbench = type
	sprite.material.set("shader_parameter/width",1)


func _on_interactable_area_stop_interact_with_player() -> void:
	if GlobalData.current_workbench == type:
		GlobalData.current_workbench = Type.None
	sprite.material.set("shader_parameter/width",0)
