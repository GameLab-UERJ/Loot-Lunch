extends Node2D
class_name SummonEntrance
## ENTRADA DE UM SUMMON: o "show" que acontece ANTES do summon aparecer no mapa
## (ovo caindo do céu e chocando o pato, buraco do inferno de onde sai o demoninho...).
##
## Quem usa é a SummonAbility (campo `entrance_scene`). Ela:
##   1. cria o summon (ainda FORA da fase) e passa em `creature`;
##   2. cria esta entrada perto do chef, no chão;
##   3. espera o sinal `summon_ready(onde)` e só então coloca o summon na fase, ali;
##   4. a entrada continua sozinha o que falta (buraco fecha, casca some...) e se apaga.
##
## Para criar uma entrada nova: script `extends SummonEntrance` e sobrescreva
##   `_before_summon()`  (o show até o summon aparecer; pode usar await)
##   `_after_summon()`   (o que acontece depois; pode usar await)
## e chame nada mais: `summon_ready` é emitido entre os dois.
##
## Se a entrada sumir antes da hora (fase trocou, cliente foi embora), `summon_ready` sai
## com `Vector2.INF` e a magia desiste do summon.


## Hora do summon aparecer, em `at` (posição global). `Vector2.INF` = cancelado.
signal summon_ready(at: Vector2)
signal finished


## Onde o summon aparece, em relação a esta entrada.
@export var summon_offset: Vector2 = Vector2.ZERO
## A entrada já mostra o summon chegando: desliga o "pop"/"invocar" dele ao nascer.
@export var skip_summon_intro: bool = false


## O summon que vai sair daqui (ainda não está na fase). Preenchido pela magia.
var creature: Node2D = null
## O chef que motivou a invocação (pode ser null).
var target: Node2D = null
## O cliente que invocou.
var caster: Node2D = null

var _released: bool = false


func _ready() -> void:
	# Adiado: quem criou a entrada precisa de um instante para começar a esperar o sinal.
	_run.call_deferred()


func _exit_tree() -> void:
	if not _released:
		_released = true
		summon_ready.emit(Vector2.INF)
		# Ninguém recolheu o summon que ia sair daqui: apaga para não ficar perdido.
		if is_instance_valid(creature) and not creature.is_inside_tree():
			creature.free()


## Já liberou o summon?
func is_released() -> bool:
	return _released


## Onde o summon vai aparecer (global).
func get_summon_position() -> Vector2:
	return global_position + summon_offset


# --- Para sobrescrever ---------------------------------------------------------

## O show antes do summon aparecer.
func _before_summon() -> void:
	pass


## O que acontece depois que o summon apareceu (o summon já está na fase).
func _after_summon() -> void:
	pass


# --- Interno -------------------------------------------------------------------

func _run() -> void:
	if not is_inside_tree():
		return
	await _before_summon()
	if not is_inside_tree():
		return
	_released = true
	summon_ready.emit(get_summon_position())
	await _after_summon()
	if not is_inside_tree():
		return
	finished.emit()
	queue_free()
