extends Node2D
class_name CustomerLane
## UM LADO por onde chegam clientes: a fila (QueueManager), o ponto de entrada (de onde
## eles vêm andando) e para onde fica a "frente" deles (o lado da cozinha).
##
## O `CustomerWaveDirector` sorteia entre várias lanes (cima, baixo, esquerda, direita).


@export var queue: QueueManager
## De onde o cliente vem andando (fora da tela).
@export var spawn_point: Node2D
## Para onde o cliente olha (a cozinha). Cima = Vector2.DOWN, baixo = Vector2.UP...
@export var front: Vector2 = Vector2.UP


func has_space() -> bool:
	return queue != null and queue.has_space()


func count() -> int:
	return queue.current_size() if queue else 0
