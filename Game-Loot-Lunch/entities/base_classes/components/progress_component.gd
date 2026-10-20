extends Node
class_name ProgressComponent
## Progresso por ETAPAS (apertar uma tecla várias vezes): cortar na tábua,
## amassar, bater, martelar... Só conta as etapas e avisa. Quem usa decide o que fazer.
##
## Irmão do CooldownComponent: lá o progresso vem do tempo, aqui vem do jogador.


signal started(total_steps: int)
signal step_added(current_steps: int, total_steps: int)
signal completed


## Quantas vezes é preciso apertar para terminar a tarefa.
@export_range(1, 50) var required_steps: int = 5


var current_steps: int = 0
## Total da tarefa em andamento (pode vir de uma receita, não só do @export).
var total_steps: int = 0


## Inicia uma tarefa nova. `custom_total` <= 0 usa `required_steps`.
func begin(custom_total: int = -1) -> void:
	total_steps = required_steps if custom_total <= 0 else custom_total
	current_steps = 0
	started.emit(total_steps)


## Conta uma etapa. Retorna true no momento em que a tarefa termina.
func add_step(amount: int = 1) -> bool:
	if total_steps <= 0 or is_complete():
		return false

	current_steps = mini(current_steps + amount, total_steps)
	step_added.emit(current_steps, total_steps)

	if is_complete():
		completed.emit()
		return true
	return false


func reset() -> void:
	current_steps = 0
	total_steps = 0


## Tem tarefa em andamento (já começou e ainda não acabou)?
func is_running() -> bool:
	return total_steps > 0 and current_steps < total_steps


func is_complete() -> bool:
	return total_steps > 0 and current_steps >= total_steps


## 0.0 = acabou de começar, 1.0 = pronto.
func get_progress() -> float:
	if total_steps <= 0:
		return 0.0
	return float(current_steps) / float(total_steps)


## Quantas etapas ainda faltam.
func get_remaining() -> int:
	return maxi(total_steps - current_steps, 0)
