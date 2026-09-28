extends Resource
class_name OrderOption
## Uma opção do CARDÁPIO de pedidos: o que o cliente pensa (ícones do balão),
## a chance de ser sorteada (peso) e qual item resolve o pedido em cada ponto.
##
## Crie um .tres por opção: botão direito no FileSystem > New Resource > OrderOption.
## Ex.: pedido_misto.tres -> ícones [carne, cogumelo], peso 35,
##      no ponto = espetinho_misto_perfeito, torrado = espetinho_misto_torrado.


@export var id: StringName = &""
@export var display_name: String = ""
## Ícones que aparecem dentro do balão, da esquerda para a direita. Pode repetir o mesmo.
@export var icons: Array[Texture2D] = []
## Peso no sorteio. Chance = peso / soma dos pesos de todas as opções do OrderComponent.
@export_range(0.0, 100.0, 0.1, "or_greater") var weight: float = 1.0

@export_group("Item que resolve o pedido")
@export var perfect_item: ItemData
@export var burnt_item: ItemData


## Item esperado para o ponto pedido (CustomerOrder.CookPoint).
func get_item_for(cook_point: int) -> ItemData:
	if cook_point == CustomerOrder.CookPoint.BURNT:
		return burnt_item
	return perfect_item
