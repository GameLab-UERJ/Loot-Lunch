extends Area2D
class_name ClickableArea

signal follow_mouse
signal stop_following_mouse


var _is_clickable : bool = false
var is_following_mouse : bool = false


# Called when the node enters the scene tree for the first time.
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event : InputEventMouseButton = event
	if _is_clickable and not is_following_mouse and mouse_event.is_action_pressed("click"):
		is_following_mouse = true
		follow_mouse.emit()
	if is_following_mouse and mouse_event.is_action_released("click"):
		is_following_mouse = false
		stop_following_mouse.emit()


func _on_mouse_entered() -> void:
	_is_clickable = true


func _on_mouse_exited() -> void:
	_is_clickable = false
