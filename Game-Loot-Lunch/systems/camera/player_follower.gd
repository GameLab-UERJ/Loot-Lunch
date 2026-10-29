extends Camera2D
class_name PlayerFollowerCamera


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	global_position = global_position.round()
