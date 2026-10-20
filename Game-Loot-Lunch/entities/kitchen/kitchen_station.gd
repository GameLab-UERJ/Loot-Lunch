extends StaticBody2D
class_name KitchenStation
## Base para tudo da cozinha que reage à interação (tecla ESPAÇO) e,
## opcionalmente, à ação secundária de descarte (tecla R).
## Filhos sobrescrevem `_interact(actor, actor_hand)` e/ou `_alt_interact(actor, actor_hand)`.
##
## ESPAÇO FAZ TUDO: o chef só usa a estação se ela REAGIRIA agora (`_can_interact`);
## senão o ESPAÇO pega/larga item do chão. Toda estação nova deve responder
## `_can_interact` com a mesma regra do seu `_interact`.


@onready var interactable: InteractableComponent = $InteractableComponent


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	interactable.alt_interacted.connect(_on_alt_interacted)


## A interação principal (ESPAÇO) faria algo agora? Chamado pelo InteractableComponent.
func can_react_to(actor: Node) -> bool:
	return _can_interact(actor, HandComponent.find_in(actor))


func _on_interacted(actor: Node) -> void:
	_interact(actor, HandComponent.find_in(actor))


func _on_alt_interacted(actor: Node) -> void:
	_alt_interact(actor, HandComponent.find_in(actor))


## Arte principal da estação: o filho "Visual" (ex.: RegrowSprite animado) ou, nas cenas
## antigas, o filho "Sprite2D". Null se não tiver nenhum.
static func find_visual(station: Node) -> CanvasItem:
	var node: Node = station.get_node_or_null("Visual")
	if node == null:
		node = station.get_node_or_null("Sprite2D")
	return node as CanvasItem


## Virtual. `actor_hand` pode ser null se quem interagiu não tem mão.
func _interact(_actor: Node, _actor_hand: HandComponent) -> void:
	pass


## Virtual: `_interact` faria algo agora? Padrão: sim (estação antiga continua funcionando).
func _can_interact(_actor: Node, _actor_hand: HandComponent) -> bool:
	return true


## Virtual da ação SECUNDÁRIA (tecla R): descartar/limpar. Por padrão não faz nada.
func _alt_interact(_actor: Node, _actor_hand: HandComponent) -> void:
	pass
