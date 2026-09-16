extends KitchenStation
class_name CounterStation
## Bancada: guarda 1 item em cima. Reusa o HandComponent como "slot".
## B com item na mão + bancada vazia  -> coloca o item.
## B com mão vazia  + bancada com item -> pega o item.


@onready var slot: HandComponent = $ItemSlot


func _interact(_actor: Node, actor_hand: HandComponent) -> void:
	if actor_hand == null:
		return

	if actor_hand.has_item() and slot.is_empty():
		actor_hand.transfer_to(slot)
	elif actor_hand.is_empty() and slot.has_item():
		slot.transfer_to(actor_hand)
