extends KitchenStation
class_name CounterStation
## Bancada: guarda 1 item em cima. Reusa o HandComponent como "slot".
## ESPAÇO com item + bancada vazia -> coloca o item.
## ESPAÇO sem item + bancada com item -> pega o item.


@onready var slot: HandComponent = $ItemSlot


func _can_interact(_actor: Node, actor_hand: HandComponent) -> bool:
	if actor_hand == null:
		return false
	return (actor_hand.has_item() and slot.is_empty()) or (actor_hand.is_empty() and slot.has_item())


func _interact(_actor: Node, actor_hand: HandComponent) -> void:
	if actor_hand == null:
		return

	if actor_hand.has_item() and slot.is_empty():
		actor_hand.transfer_to(slot)
	elif actor_hand.is_empty() and slot.has_item():
		slot.transfer_to(actor_hand)
