extends Node
class_name DeliveryRewardComponent
## RECOMPENSA POR ENTREGA: quando o dono entrega um pedido (na mão, largando ou
## arremessando), recupera VIDA e MANA.
##
## Não sabe de cliente nem de pedido: o OrderPaymentComponent do cliente procura este
## componente em quem entregou (igual faz com a carteira) e chama `on_delivered(certo)`.
##
## Vida é em PONTOS (2 = 1 caveira, 1 = meia caveira), igual ao `max_hp` do Chef.
## Mana é em barras (ManaComponent do dono).
##
## Colocar como filho do Chef. Cada chef pode ter recompensas diferentes.


signal rewarded(correct: bool, health: int, mana: int)


@export_group("Pedido certo")
@export_range(0, 20) var heal_on_correct: int = 2
@export_range(0, 10) var mana_on_correct: int = 1

@export_group("Pedido errado")
@export_range(0, 20) var heal_on_wrong: int = 1
@export_range(0, 10) var mana_on_wrong: int = 0

@export_group("Texto flutuante")
@export var show_floating_text: bool = true
@export var text_offset: Vector2 = Vector2(0, -26)
@export var text_color: Color = Color(0.6, 0.85, 1.0)


## Encontra o DeliveryRewardComponent filho direto de um nó (ex.: o Chef).
static func find_in(node: Node) -> DeliveryRewardComponent:
	if node == null:
		return null
	for child in node.get_children():
		if child is DeliveryRewardComponent:
			return child
	return null


func on_delivered(correct: bool) -> void:
	var user: Node = get_parent()
	var heal_amount: int = heal_on_correct if correct else heal_on_wrong
	var mana_amount: int = mana_on_correct if correct else mana_on_wrong

	# Só conta o que de fato recuperou (vida/mana cheia não mostra texto).
	var healed: int = 0
	if heal_amount > 0 and user.has_method(&"heal"):
		var before: int = int(user.get(&"hp"))
		user.call(&"heal", heal_amount)
		healed = int(user.get(&"hp")) - before

	var restored: int = 0
	var mana: ManaComponent = ManaComponent.find_in(user)
	if mana and mana_amount > 0:
		var before_mana: int = mana.mana
		mana.restore(mana_amount)
		restored = mana.mana - before_mana

	if show_floating_text and (healed > 0 or restored > 0):
		_show_text(user, healed, restored)
	rewarded.emit(correct, healed, restored)


func _show_text(user: Node, healed: int, restored: int) -> void:
	if not (user is Node2D):
		return
	var parts: PackedStringArray = []
	if healed > 0:
		parts.append("+%s vida" % _format_health(healed))
	if restored > 0:
		parts.append("+%d mana" % restored)
	var parent: Node = get_tree().current_scene if get_tree().current_scene else user.get_parent()
	FloatingText.spawn(parent, (user as Node2D).global_position + text_offset,
		"  ".join(parts), text_color)


## 2 pontos = "1", 1 ponto = "½", 3 pontos = "1½".
func _format_health(points: int) -> String:
	var whole: int = points / 2
	var half: bool = points % 2 == 1
	if whole == 0:
		return "½"
	return str(whole) + ("½" if half else "")
