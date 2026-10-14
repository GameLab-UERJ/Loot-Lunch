extends Resource
class_name LevelData
## DADOS de uma fase do restaurante: quanto tempo dura, quanto dinheiro precisa fazer e
## como os clientes chegam. A cena da fase (RestaurantLevel) só lê este arquivo.
##
## Mesma regra do resto do projeto: **a fase é cena, a dificuldade é dado.**
## Fase nova com outro ritmo = outro .tres (Botão direito > New Resource > LevelData).


@export var display_name: String = "Fase 1"

@export_group("Turno")
## Duração do turno em segundos.
@export var duration: float = 180.0
## Dinheiro que o chef precisa ter no fim do turno para passar.
@export var money_goal: int = 60
## Se o chef cair (vida 0), a fase termina na hora como derrota.
@export var fail_on_chef_death: bool = true

@export_group("Clientes")
## Quem pode aparecer. O diretor sorteia, evitando repetir quem já está na fila.
@export var customer_scenes: Array[PackedScene] = []
## Quantos clientes cabem na fila do balcão ao mesmo tempo.
@export_range(1, 8) var max_customers: int = 3
## Segundos até o primeiro cliente chegar.
@export var first_spawn_delay: float = 2.0
## Intervalo sorteado entre um cliente e o próximo (segundos).
@export var spawn_interval_min: float = 10.0
@export var spawn_interval_max: float = 16.0
## Segundos de paciência de cada cliente (a barra inteira).
@export var patience_time: float = 60.0
## Limites da barra de paciência (o que AINDA RESTA, 0..1) que soltam as magias 1, 2 e 3,
## do maior para o menor. [0.5, 0.3, 0.1] = magia 1 com 50% da barra gasta, magia 2 com
## 70% e magia 3 com 90%. Com 100% gasta o cliente vai embora.
@export var ability_thresholds: Array[float] = [0.5, 0.3, 0.1]

@export_group("Pedido")
## Distância (px) do chef até o cliente para o balão do pedido aparecer.
@export var order_reveal_distance: float = 96.0


## Intervalo sorteado até o próximo cliente.
func roll_spawn_interval() -> float:
	var low: float = minf(spawn_interval_min, spawn_interval_max)
	var high: float = maxf(spawn_interval_min, spawn_interval_max)
	return randf_range(low, high)
