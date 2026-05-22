extends Area2D
class_name ClickableArea


var _is_clickable : bool = false
var is_following_mouse : bool = false


func _on_mouse_entered() -> void:
	_is_clickable = true


func _on_mouse_exited() -> void:
	_is_clickable = false
