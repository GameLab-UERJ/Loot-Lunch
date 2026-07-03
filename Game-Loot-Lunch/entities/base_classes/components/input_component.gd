extends Node
class_name InputComponent


signal direction_changed(new_movement_direction : Vector2)


func get_input() -> void:
	var mov_direction : Vector2 = Vector2.ZERO
	if Input.is_action_pressed("ui_down"):
		mov_direction += Vector2.DOWN
	if Input.is_action_pressed("ui_left"):
		mov_direction += Vector2.LEFT
	if Input.is_action_pressed("ui_right"):
		mov_direction += Vector2.RIGHT
	if Input.is_action_pressed("ui_up"):
		mov_direction += Vector2.UP
	
	direction_changed.emit(mov_direction)
