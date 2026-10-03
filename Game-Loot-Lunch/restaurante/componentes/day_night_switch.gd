extends RefCounted
class_name DayNightSwitch
## Liga/desliga o efeito de DIA E NOITE do jogo (feito fora do restaurante, em
## systems/time_cycle/) SEM mexer nele: só usa o autoload EnvironmentManager.
##
## O autoload DayNightCycle (CanvasModulate que escurece a tela à noite + sons de
## ambiente) só aparece quando `EnvironmentManager.is_outdoor` é true. Cenas internas
## (restaurante, minigames) chamam no _ready:
##
##     DayNightSwitch.disable(self)
##
## Busca o autoload pelo caminho (/root/EnvironmentManager) para não quebrar se a cena
## rodar sem ele (testes, F6 sem os autoloads).


## Desliga o efeito (cena interna: sem escurecer, sem som de passarinho/grilo).
static func disable(from: Node) -> void:
	_set_outdoor(from, false)


## Liga de novo (voltando para uma área externa).
static func enable(from: Node) -> void:
	_set_outdoor(from, true)


static func _set_outdoor(from: Node, value: bool) -> void:
	if from == null or not from.is_inside_tree():
		return
	var manager: Node = from.get_node_or_null(^"/root/EnvironmentManager")
	if manager and &"is_outdoor" in manager:
		manager.set(&"is_outdoor", value)
