extends Node
class_name BattleSkill
## BASE de toda HABILIDADE DO CHEF na batalha por turnos (Frigideirada, Investida
## Sombria, Besta, Devorar...). Mesma ideia do AbilityComponent do restaurante:
## o chef e o menu não sabem o que cada uma faz.
##
## Quem herda sobrescreve:
##   `_can_use(user, target)`  -> condição extra (ex.: Devorar só abaixo de 20%)
##   `_execute(battle, user, target)` -> a animação + o dano (pode usar `await`)
##
## Mana: `mana_cost` é gasto ao usar; `mana_gain` é recuperado (golpe básico recarrega).
## Nova habilidade: script que `extends BattleSkill` + nó filho do ChefBattler.


@export var display_name: String = "Habilidade"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_range(0, 10) var mana_cost: int = 0
@export_range(0, 10) var mana_gain: int = 0
@export var enabled: bool = true


## Todas as habilidades filhas diretas de um nó (na ordem da árvore = ordem do menu).
static func find_all_in(node: Node) -> Array[BattleSkill]:
	var found: Array[BattleSkill] = []
	if node == null:
		return found
	for child in node.get_children():
		if child is BattleSkill:
			found.append(child)
	return found


func can_use(user: ChefBattler, target: FormigaBattler) -> bool:
	return why_not(user, target) == ""


## Texto explicando por que não dá para usar agora ("" = pode usar).
func why_not(user: ChefBattler, target: FormigaBattler) -> String:
	if not enabled:
		return "Indisponível"
	if mana_cost > 0 and user.mana and not user.mana.has(mana_cost):
		return "Mana insuficiente"
	if target == null or target.is_dead():
		return "Sem alvo"
	return _why_not(user, target)


## Usa a habilidade (gasta mana, anima, dá dano). Uso: `await skill.execute(...)`.
func execute(battle: TurnBattle, user: ChefBattler, target: FormigaBattler) -> void:
	if user.mana and mana_cost > 0:
		user.mana.try_spend(mana_cost)
	await _execute(battle, user, target)
	if user.mana and mana_gain > 0:
		user.mana.restore(mana_gain)


# --- Para sobrescrever -------------------------------------------------------

func _why_not(_user: ChefBattler, _target: FormigaBattler) -> String:
	return ""


func _execute(_battle: TurnBattle, _user: ChefBattler, _target: FormigaBattler) -> void:
	pass
