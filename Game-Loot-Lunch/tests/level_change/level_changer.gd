extends Area2D

@export var next_level =""


	
func load_next_scene():
	get_tree().change_scene_to_file(next_level)


func _on_body_entered(body: Node2D) -> void:
	call_deferred("load_next_scene")
