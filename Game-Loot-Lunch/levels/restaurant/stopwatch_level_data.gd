extends LevelData
class_name StopwatchLevelData
## DADOS de uma fase com CRONÔMETRO (ex.: fase 1-1 do Reino Caveira).
##
## Diferente da fase com turno (LevelData puro), aqui o relógio anda PARA FRENTE:
## a fase acaba quando todos os `total_customers` forem atendidos, e as estrelas vêm
## de QUANTOS pedidos saíram certos e de QUANTO TEMPO os jogadores levaram.
##
## Reaproveita do LevelData: nome, clientes (`customer_scenes`), ritmo de chegada,
## paciência, limites das magias, distância do pedido e `fail_on_chef_death`.
## Ignora: `duration`, `money_goal`, `star_goals` (são da fase com turno).


@export var level_id: String = "1-1"

@export_group("Clientes da fase")
## Quantos clientes a fase tem no total. Acaba quando todos forem atendidos.
@export var total_customers: int = 20
## Quantos clientes podem estar esperando ao mesmo tempo (somando todos os lados).
@export_range(1, 32) var max_simultaneous: int = 12
## true = o cliente NÃO vai embora quando a paciência acaba (fica até ser atendido).
## O que ele faz com a paciência em 0 depende de `rage_when_patience_ends`.
@export var customers_stay_until_served: bool = true

@export_group("Raiva pura")
## true = paciência em 0 -> RAIVA PURA: a barra fica vazia e o cliente lança as magias de
## `rage_ability_levels` sem parar até ser atendido.
## false = a barra recomeça (um pouco menor, ver abaixo) e ele volta a lançar pelos limites.
@export var rage_when_patience_ends: bool = true
## Magias usadas na raiva (1 = magia 1, 2 = magia 2...). Ponha 3 para liberar a ultimate.
@export var rage_ability_levels: Array[int] = [1, 2]
## Segundos entre uma magia e outra na raiva. Menor = mais desenfreado.
@export var rage_cast_interval: float = 1.0
## Recarga mínima (s) de cada magia na raiva: nível -> segundos. Ex.: {1: 3.0} = a magia 1
## sai no máximo a cada 3s (nos outros sorteios sai a magia 2). Nível fora da lista = sem recarga.
@export var rage_level_cooldowns: Dictionary[int, float] = {1: 3.0}
## (Só com a raiva desligada) a cada volta, a próxima barra fica este tanto do tempo.
@export_range(0.2, 1.0) var furious_patience_scale: float = 0.8
## (Só com a raiva desligada) paciência mínima (s) depois de várias voltas.
@export var min_patience_time: float = 20.0

@export_group("Estrelas")
## Pedidos CERTOS mínimos para cada estrela (da 1ª para a última).
## A 1ª estrela é o mínimo para passar de fase.
@export var star_min_correct: Array[int] = [10, 15, 18]
## Tempo MÁXIMO (s) para cada estrela. 0 = sem limite de tempo.
@export var star_max_time: Array[float] = [0.0, 540.0, 420.0]


func get_max_stars() -> int:
	return star_min_correct.size()


## Estrelas de um resultado final.
func stars_for_result(seconds: float, correct: int) -> int:
	var stars: int = 0
	for i in get_max_stars():
		if _meets(i, seconds, correct):
			stars += 1
	return stars


## A estrela `index` (0 = 1ª) ainda dá para pegar? (tempo não estourou e ainda há
## clientes suficientes para chegar no número de certos)
func is_star_reachable(index: int, seconds: float, correct: int, remaining: int) -> bool:
	if index < 0 or index >= get_max_stars():
		return false
	var limit: float = star_max_time[index] if index < star_max_time.size() else 0.0
	if limit > 0.0 and seconds > limit:
		return false
	return correct + remaining >= star_min_correct[index]


## Quantas estrelas ainda dá para pegar agora.
func reachable_stars(seconds: float, correct: int, remaining: int) -> int:
	var stars: int = 0
	for i in get_max_stars():
		if is_star_reachable(i, seconds, correct, remaining):
			stars += 1
	return stars


func time_limit_of(index: int) -> float:
	return star_max_time[index] if index >= 0 and index < star_max_time.size() else 0.0


func _meets(index: int, seconds: float, correct: int) -> bool:
	var limit: float = time_limit_of(index)
	return correct >= star_min_correct[index] and (limit <= 0.0 or seconds <= limit)
