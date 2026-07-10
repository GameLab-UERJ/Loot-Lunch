extends Area2D

var item_name: String = "Tomate"
@export var raio_coleta: float = 20.0

func _process(delta: float) -> void:
	var player = get_tree().current_scene.find_child("Player", true, false)
	
	if player:
		var distancia = global_position.distance_to(player.global_position)
		if distancia < raio_coleta:
			queue_free()
			print("Essa desgraça funcionouuuu ( diferente do area_entered, por isso tive q por assim )")
