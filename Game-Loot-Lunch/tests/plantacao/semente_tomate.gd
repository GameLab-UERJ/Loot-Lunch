extends Area2D

const tomate_crescendo = preload("res://tests/plantacao/tomate_crescendo.tscn") 

func _ready() -> void:
	TimeCycle.day_started.connect(_on_day_started)

func _on_day_started() -> void:
	brotar_tomate()

func brotar_tomate():
	var pe_de_tomate = tomate_crescendo.instantiate()
	pe_de_tomate.global_position = global_position
	get_parent().add_child(pe_de_tomate)
	
	queue_free()
