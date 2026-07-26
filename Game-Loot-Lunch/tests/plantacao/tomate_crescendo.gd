extends Area2D

const cena_tomate = preload("res://tests/plantacao/tomate.tscn") 

@onready var sprite = $AnimatedSprite2D
@onready var timer = $Timer
@export var quantidade_por_vez: int = 1
@export var max_itens_no_chao: int = 3
@export var raio_busca: float = 60.0

var estagio_atual = 0

func _ready() -> void:
	sprite.frame = 0
	timer.start()
	TimeCycle.day_started.connect(_on_day_started)


func _on_timer_timeout() -> void:
	if estagio_atual < 4:
		estagio_atual += 1
		sprite.frame = estagio_atual
		
		if estagio_atual == 4:
			timer.stop() 
			_tentar_dropar_tomates()
	else:
		timer.stop()


func _on_day_started() -> void:
	if estagio_atual == 4:
		_tentar_dropar_tomates()


func _tentar_dropar_tomates() -> void:
	var quantidade_atual_no_chao = _contar_itens_do_tipo_perto()
	if quantidade_atual_no_chao < max_itens_no_chao:
		var espaco_disponivel = max_itens_no_chao - quantidade_atual_no_chao
		var quantidade_a_dropar = min(quantidade_por_vez, espaco_disponivel)
		
		for i in range(quantidade_a_dropar):
			dropar_novo_tomate()

func _contar_itens_do_tipo_perto() -> int:
	var contador = 0
	var todos_os_itens = get_tree().get_nodes_in_group("itens_dropados")
	
	for item in todos_os_itens:
		if item is Item and item.item_name == "Tomate":
			if global_position.distance_to(item.global_position) < raio_busca:
				contador += 1
	return contador


func dropar_novo_tomate() -> void:
	var novo_drop = cena_tomate.instantiate()
	novo_drop.add_to_group("itens_dropados")
	
	var variacao_posicao = Vector2(randf_range(-10, 10), randf_range(5, 20))
	novo_drop.global_position = global_position + variacao_posicao
	
	get_parent().add_child(novo_drop)
