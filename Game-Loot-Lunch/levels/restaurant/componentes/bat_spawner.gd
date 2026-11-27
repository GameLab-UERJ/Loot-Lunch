extends Node2D
class_name BatSpawner
## Solta MORCEGOS (ou qualquer inimigo voador) pelas bordas da tela durante a fase.
##
## Coloque na fase e aponte `level` (StopwatchLevel): começa quando o relógio anda
## (`level_started`) e, no fim da fase (`level_finished`), para e manda os morcegos
## vivos irem embora. Sem `level`, use `start()` / `stop()` à mão (ou `auto_start`).
##
## Ritmo: o 1º sai depois de `first_delay`; depois, um a cada `interval_min..max` s,
## nunca mais que `max_alive` vivos ao mesmo tempo. `total` limita quantos saem na fase
## (0 = sem limite). Com `ramp_after` > 0, depois desse tempo o limite vivo sobe para
## `max_alive_late` (a fase vai apertando).


signal spawned(enemy: Node2D)


@export var enemy_scene: PackedScene
## Onde os morcegos entram na árvore. Vazio = o pai deste nó.
@export var container: Node
## Fase que liga/desliga o spawner. Vazio = controle manual.
@export var level: StopwatchLevel
@export var auto_start: bool = false

@export_group("Ritmo")
@export var first_delay: float = 12.0
@export var interval_min: float = 7.0
@export var interval_max: float = 12.0
@export_range(1, 20) var max_alive: int = 2
## Segundos de fase até o limite subir para `max_alive_late`. 0 = nunca sobe.
@export var ramp_after: float = 120.0
@export_range(1, 20) var max_alive_late: int = 3
## Quantos saem na fase inteira. 0 = sem limite.
@export var total: int = 0

@export_group("Onde")
## Área de voo (coordenadas globais). Os morcegos nascem FORA dela, na borda, e ficam
## presos dentro depois de entrar.
@export var arena: Rect2 = Rect2(16, 16, 608, 328)
## Distância fora da arena onde eles nascem.
@export var spawn_margin: float = 28.0


var spawned_count: int = 0
var _running: bool = false
var _time_to_next: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	if level:
		level.level_started.connect(start)
		level.level_finished.connect(func(_success: bool, _stars: int) -> void: stop(true))
	elif auto_start:
		start()


func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	_time_to_next -= delta
	if _time_to_next > 0.0:
		return
	if total > 0 and spawned_count >= total:
		_running = false
		return
	if get_alive_count() < get_max_alive():
		spawn_one()
	_time_to_next = randf_range(interval_min, interval_max)


func start() -> void:
	if _running:
		return
	_running = true
	_elapsed = 0.0
	_time_to_next = first_delay


## Para de soltar. `send_away` = os vivos vão embora voando.
func stop(send_away: bool = false) -> void:
	_running = false
	if not send_away:
		return
	for enemy in get_alive():
		if enemy.has_method("flee"):
			enemy.flee()
		else:
			enemy.queue_free()


func get_max_alive() -> int:
	return max_alive_late if ramp_after > 0.0 and _elapsed >= ramp_after else max_alive


func get_alive() -> Array[Node2D]:
	var alive: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(Morcego.GROUP):
		var enemy := node as Node2D
		if enemy and not enemy.is_queued_for_deletion() \
				and not (enemy.has_method("is_dead") and enemy.is_dead()):
			alive.append(enemy)
	return alive


func get_alive_count() -> int:
	return get_alive().size()


func spawn_one() -> Node2D:
	if enemy_scene == null:
		push_warning("BatSpawner '%s': sem enemy_scene." % name)
		return null
	var enemy := enemy_scene.instantiate() as Node2D
	if "arena" in enemy:
		enemy.arena = arena
	var parent: Node = container if container else get_parent()
	parent.add_child(enemy)
	enemy.global_position = random_edge_point()
	spawned_count += 1
	spawned.emit(enemy)
	return enemy


## Ponto sorteado numa das 4 bordas, `spawn_margin` para fora da arena.
func random_edge_point() -> Vector2:
	var outer: Rect2 = arena.grow(spawn_margin)
	match randi() % 4:
		0:
			return Vector2(randf_range(outer.position.x, outer.end.x), outer.position.y)
		1:
			return Vector2(randf_range(outer.position.x, outer.end.x), outer.end.y)
		2:
			return Vector2(outer.position.x, randf_range(outer.position.y, outer.end.y))
		_:
			return Vector2(outer.end.x, randf_range(outer.position.y, outer.end.y))
