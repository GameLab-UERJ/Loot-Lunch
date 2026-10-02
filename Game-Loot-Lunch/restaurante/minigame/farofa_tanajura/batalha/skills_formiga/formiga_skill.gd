extends Node
class_name FormigaSkill
## BASE de todo ATAQUE DA FORMIGA. Cada ataque é também um QTE de DEFESA do chef:
## a habilidade anima a formiga, arma o QteTrack da batalha e decide o que acontece
## se o jogador acertou ou errou o tempo.
##
## Quem herda sobrescreve `_execute(battle, ant, chef)` (pode usar `await`).
## Escolha por sorteio no FormigaBattler (`weight`). Novo ataque = novo nó filho da formiga.


@export var display_name: String = "Ataque"
## Chance relativa de ser sorteado.
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
## Dano no chef se ele NÃO se defender (em meias caveiras).
@export_range(0, 10) var damage: int = 2
@export var enabled: bool = true


static func find_all_in(node: Node) -> Array[FormigaSkill]:
	var found: Array[FormigaSkill] = []
	if node == null:
		return found
	for child in node.get_children():
		if child is FormigaSkill:
			found.append(child)
	return found


func execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	battle.announce("%s usou %s!" % [ant.display_name, display_name], Color(1.0, 0.7, 0.5))
	await _execute(battle, ant, chef)


func _execute(_battle: TurnBattle, _ant: FormigaBattler, _chef: ChefBattler) -> void:
	pass
