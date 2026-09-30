extends Node
class_name AbilityComponent
## BASE de toda HABILIDADE (arremesso do espetinho, sombra, futuras...).
##
## Cuida só do que é comum a todas:
##   - qual ação do Input Map ativa (`action`)
##   - quanto de mana gasta (`mana_cost`, procura o ManaComponent no dono)
##   - apertar / soltar / ser interrompida (levou dano, morreu)
##
## Quem herda sobrescreve `_on_press`, `_on_release`, `_on_interrupt` e `is_busy`.
## O dono (ex.: Chef) só repassa as teclas: `press()` ao apertar, `release()` ao soltar,
## `interrupt()` ao levar dano. Ele NÃO precisa saber o que cada habilidade faz.
##
## Nova habilidade: crie um script que `extends AbilityComponent`, coloque o nó como
## filho do Chef e escolha a `action`. Nada mais muda no Chef.


## A habilidade foi usada de verdade (gastou mana).
signal activated
## Foi cancelada no meio (soltou cedo, levou dano...).
signal interrupted
## Tentou usar sem mana.
signal not_enough_mana


## Ação do Input Map (Projeto > Configurações > Mapa de Entrada).
@export var action: StringName = &""
## Quantas barras de mana gasta. 0 = de graça.
@export_range(0, 10) var mana_cost: int = 1
@export var enabled: bool = true


## Quem usa a habilidade (o nó pai, ex.: o Chef).
var user: Node = null
## Mana do dono. Sem ManaComponent = habilidade de graça.
var mana: ManaComponent = null


## Todas as habilidades filhas diretas de um nó.
static func find_all_in(node: Node) -> Array[AbilityComponent]:
	var found: Array[AbilityComponent] = []
	if node == null:
		return found
	for child in node.get_children():
		if child is AbilityComponent:
			found.append(child)
	return found


func _ready() -> void:
	user = get_parent()
	mana = ManaComponent.find_in(user)


# --- Chamado pelo dono ---------------------------------------------------------

## Apertou a tecla. Retorna true se a habilidade começou.
func press() -> bool:
	if not enabled or is_busy():
		return false
	return _on_press()


## Soltou a tecla.
func release() -> void:
	if enabled:
		_on_release()


## Levou dano / morreu / perdeu o controle: cancela o que estiver fazendo.
func interrupt() -> void:
	if is_busy():
		_on_interrupt()
		interrupted.emit()


## Enquanto true, o dono não deve fazer outras ações (B, R, T, dash...).
func is_busy() -> bool:
	return false


## Enquanto true, a habilidade decide para onde o dono olha (ex.: mira do mouse)
## e andar não vira o personagem.
func controls_facing() -> bool:
	return false


# --- Mana ----------------------------------------------------------------------

func has_mana() -> bool:
	return mana == null or mana.has(mana_cost)


## Confere a mana e, se faltar, avisa (a barra treme). Não gasta nada.
func check_mana() -> bool:
	if has_mana():
		return true
	if mana:
		mana.insufficient.emit(mana_cost, mana.mana)
	not_enough_mana.emit()
	return false


func spend_mana() -> bool:
	if mana == null:
		return true
	if mana.try_spend(mana_cost):
		return true
	not_enough_mana.emit()
	return false


# --- Para sobrescrever ---------------------------------------------------------

func _on_press() -> bool:
	return false


func _on_release() -> void:
	pass


func _on_interrupt() -> void:
	pass
