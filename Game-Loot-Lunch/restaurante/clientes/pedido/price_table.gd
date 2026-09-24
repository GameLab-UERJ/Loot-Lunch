extends Resource
class_name PriceTable
## TABELA DE PREÇOS do cardápio: quanto cada pedido paga.
## Funciona como um dicionário: `id do OrderOption` -> preço.
##
## Crie/edite no Inspector (arquivo dados/tabela_precos.tres):
##   prices = { "pedido_carne": 10, "pedido_cogumelo": 10, "pedido_misto": 10 }
## Pedido novo que não estiver na tabela paga `default_price`.
##
## Regra de pagamento:
##   entrega CERTA  -> preço cheio
##   entrega ERRADA -> preço * wrong_delivery_ratio (arredondado)


## Preço de qualquer pedido que não esteja no dicionário.
@export var default_price: int = 10
## id do OrderOption (ex.: &"pedido_misto") -> preço (int).
@export var prices: Dictionary = {}
## Quanto do preço o cliente paga se receber o prato ERRADO (0.25 = 25%).
@export_range(0.0, 1.0, 0.01) var wrong_delivery_ratio: float = 0.25


## Preço cheio do pedido.
func get_price(order: CustomerOrder) -> int:
	if order == null or order.option == null:
		return default_price
	return get_price_by_id(order.option.id)


func get_price_by_id(id: StringName) -> int:
	if prices.has(id):
		return int(prices[id])
	if prices.has(String(id)):  # aceita a chave digitada como String no Inspector
		return int(prices[String(id)])
	return default_price


## Quanto o cliente paga por esta entrega.
func get_payment(order: CustomerOrder, correct: bool) -> int:
	var price: int = get_price(order)
	if correct:
		return price
	return roundi(price * wrong_delivery_ratio)
