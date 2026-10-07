extends Node
class_name BattleWaitComponent
## TEMPO DE ESPERA de quem luta (a "barra ATB" dos RPGs): enche com o tempo e, cheia,
## o dono pode agir. Depois de agir, `consume()` zera e sorteia a próxima espera.
##
##   wait.tick(delta)          # quem manda no relógio (a batalha) chama todo quadro
##   if wait.is_ready(): ...   # pode agir
##   wait.consume()            # agiu: começa a esperar de novo
##   wait.stun(2.0)            # atordoado: a barra para de encher por 2 s
##
## Não tem `_process` de propósito: a BATALHA decide quando o tempo corre (para tudo
## enquanto alguém ataca ou um QTE está rolando). Não desenha nada — quem quiser mostrar
## a barra escuta `progress_changed`.
##
## Reutilizável: chef e formigas da Fase 3, chefões futuros, torres que atiram...


signal progress_changed(ratio: float)
## A barra encheu (uma vez por espera).
signal became_ready
signal stun_changed(stunned: bool)


## Segundos para encher a barra.
@export_range(0.1, 60.0, 0.1, "suffix:s") var wait_time: float = 6.0
## Variação sorteada a cada espera (0.15 = ±15%), para o ritmo não ficar previsível.
@export_range(0.0, 0.9, 0.01) var jitter: float = 0.15
## A primeira espera começa com a barra entre estes valores (0..1), sorteado.
@export_range(0.0, 1.0, 0.01) var start_ratio_min: float = 0.0
@export_range(0.0, 1.0, 0.01) var start_ratio_max: float = 0.0
## Multiplicador de velocidade (lentidão, pressa...). 1 = normal.
@export_range(0.0, 5.0, 0.05) var speed_scale: float = 1.0


var elapsed: float = 0.0
var current_wait: float = 1.0
var stun_left: float = 0.0
var _ready_emitted: bool = false


static func find_in(node: Node) -> BattleWaitComponent:
	if node == null:
		return null
	for child in node.get_children():
		if child is BattleWaitComponent:
			return child
	return null


func _ready() -> void:
	reset()


## Volta para o começo (com a barra inicial sorteada).
func reset() -> void:
	current_wait = _roll_wait()
	elapsed = current_wait * randf_range(start_ratio_min, maxf(start_ratio_min, start_ratio_max))
	stun_left = 0.0
	_ready_emitted = false
	progress_changed.emit(get_ratio())


func tick(delta: float) -> void:
	if stun_left > 0.0:
		stun_left = maxf(stun_left - delta, 0.0)
		if stun_left <= 0.0:
			stun_changed.emit(false)
		return
	if is_ready():
		return
	elapsed = minf(elapsed + delta * speed_scale, current_wait)
	progress_changed.emit(get_ratio())
	if is_ready() and not _ready_emitted:
		_ready_emitted = true
		became_ready.emit()


func is_ready() -> bool:
	return stun_left <= 0.0 and elapsed >= current_wait


func is_stunned() -> bool:
	return stun_left > 0.0


func get_ratio() -> float:
	return clampf(elapsed / maxf(current_wait, 0.001), 0.0, 1.0)


## Agiu: zera a barra e sorteia a próxima espera.
func consume() -> void:
	current_wait = _roll_wait()
	elapsed = 0.0
	_ready_emitted = false
	progress_changed.emit(0.0)


## Atordoa: a barra não enche por `seconds` (renova, não soma).
func stun(seconds: float) -> void:
	if seconds <= 0.0:
		return
	var was: bool = is_stunned()
	stun_left = maxf(stun_left, seconds)
	if not was:
		stun_changed.emit(true)


## Empurra a barra para trás (0.3 = perde 30% do que já tinha enchido).
func knock_back(ratio: float) -> void:
	elapsed = maxf(elapsed - current_wait * ratio, 0.0)
	_ready_emitted = is_ready()
	progress_changed.emit(get_ratio())


func _roll_wait() -> float:
	return maxf(wait_time * (1.0 + randf_range(-jitter, jitter)), 0.05)
