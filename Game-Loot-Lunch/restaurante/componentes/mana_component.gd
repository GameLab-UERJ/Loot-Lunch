extends Node
class_name ManaComponent
## MANA: guarda quantas "barras" de habilidade o dono tem. Não sabe quais habilidades
## existem nem quem desenha a barra — só guarda, gasta, recupera e avisa.
##
## Reutilizável: chef, 2º jogador, inimigo que solta magia, totem...
##
## Uso:
##   var mana := ManaComponent.find_in(chef)
##   if mana.try_spend(1): ...        # gasta 1 barra (ou avisa `insufficient`)
##   mana.restore(1)                  # recupera 1 barra
## Quem quer mostrar a mana (HUD) conecta em `mana_changed`.


## Mana mudou (gasto, recuperação ou máximo novo). O HUD escuta este sinal.
signal mana_changed(current: int, maximum: int)
## Tentou gastar mais do que tem. O HUD usa para "tremer" a barra.
signal insufficient(requested: int, current: int)


## Quantidade de barras. Mude aqui para aumentar a mana no futuro (upgrade, loja...).
@export_range(0, 20) var max_mana: int = 5: set = set_max_mana
## Começa com a mana cheia. Desligado = começa com `starting_mana`.
@export var start_full: bool = true
@export_range(0, 20) var starting_mana: int = 0


var mana: int = 0


## Encontra o ManaComponent filho direto de um nó (ex.: o Chef). Retorna null se não houver.
static func find_in(node: Node) -> ManaComponent:
	if node == null:
		return null
	for child in node.get_children():
		if child is ManaComponent:
			return child
	return null


func _ready() -> void:
	mana = max_mana if start_full else clampi(starting_mana, 0, max_mana)
	mana_changed.emit(mana, max_mana)


func has(amount: int) -> bool:
	return mana >= amount


func is_full() -> bool:
	return mana >= max_mana


## Gasta `amount` barras. Retorna false (e emite `insufficient`) se não tiver o bastante.
func try_spend(amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if mana < amount:
		insufficient.emit(amount, mana)
		return false
	_set_mana(mana - amount)
	return true


## Recupera `amount` barras (sem passar do máximo).
func restore(amount: int = 1) -> void:
	if amount <= 0:
		return
	_set_mana(mini(mana + amount, max_mana))


func restore_full() -> void:
	_set_mana(max_mana)


func set_max_mana(value: int) -> void:
	max_mana = maxi(value, 0)
	if is_node_ready():
		_set_mana(mini(mana, max_mana), true)


func _set_mana(value: int, force_emit: bool = false) -> void:
	if value == mana and not force_emit:
		return
	mana = value
	mana_changed.emit(mana, max_mana)
