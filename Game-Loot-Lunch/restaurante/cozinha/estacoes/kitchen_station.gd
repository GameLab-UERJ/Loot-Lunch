extends StaticBody2D
class_name KitchenStation
## Base para tudo da cozinha que reage à interação (tecla B) e, opcionalmente,
## à ação secundária de descarte (tecla T).
## Filhos sobrescrevem `_interact(actor, actor_hand)` e/ou `_alt_interact(actor, actor_hand)`.


@onready var interactable: InteractableComponent = $InteractableComponent


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	interactable.alt_interacted.connect(_on_alt_interacted)


func _on_interacted(actor: Node) -> void:
	_interact(actor, HandComponent.find_in(actor))


func _on_alt_interacted(actor: Node) -> void:
	_alt_interact(actor, HandComponent.find_in(actor))


## Virtual. `actor_hand` pode ser null se quem interagiu não tem mão.
func _interact(_actor: Node, _actor_hand: HandComponent) -> void:
	pass


## Virtual da ação SECUNDÁRIA (tecla T): descartar/limpar. Por padrão não faz nada.
func _alt_interact(_actor: Node, _actor_hand: HandComponent) -> void:
	pass
