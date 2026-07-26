extends Area2D

const cebola_crescendo = preload("res://tests/plantacao/cebola_crescendo.tscn") 

func _ready() -> void:
	TimeCycle.day_started.connect(_on_day_started)

func _on_day_started() -> void:
	brotar_cebola()

func brotar_cebola():
	var pe_de_cebola = cebola_crescendo.instantiate()
	pe_de_cebola.global_position = global_position
	get_parent().add_child(pe_de_cebola)
	
	queue_free()
