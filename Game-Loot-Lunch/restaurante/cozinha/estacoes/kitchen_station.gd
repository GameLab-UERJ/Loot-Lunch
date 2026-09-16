extends StaticBody2D
class_name KitchenStation
## Base para tudo da cozinha que reage à interação (tecla B).
## Filhos devem sobrescrever `_interact(actor, actor_hand)`.


@onready var interactable: InteractableComponent = $InteractableComponent


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(actor: Node) -> void:
	_interact(actor, HandComponent.find_in(actor))


## Virtual. `actor_hand` pode ser null se quem interagiu não tem mão.
func _interact(_actor: Node, _actor_hand: HandComponent) -> void:
	pass
