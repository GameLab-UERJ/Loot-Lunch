extends Area2D

const pimentao_crescendo = preload("res://tests/plantacao/pimentao_crescendo.tscn") 

func _ready() -> void:
	TimeCycle.day_started.connect(_on_day_started)

func _on_day_started() -> void:
	brotar_pimentao()

func brotar_pimentao():
	var pe_de_pimentao = pimentao_crescendo.instantiate()
	pe_de_pimentao.global_position = global_position
	get_parent().add_child(pe_de_pimentao)
	
	queue_free()
