extends Node2D
class_name OrderPaymentComponent
## PAGAMENTO do pedido. Liga três peças que não se conhecem:
##
##   OrderComponent            (irmão, cena pedido.tscn)  -> o que o cliente quer
##   DeliveryReceiverComponent (filho "Recebedor")        -> recebeu um item (B ou colisão)
##   PriceTable                (.tres)                    -> quanto vale
##
## Quando um item chega: confere com o pedido, calcula o valor, paga na carteira de
## quem entregou (WalletComponent), mostra "+10 Almas" e limpa o pedido.
##
## Uso: arraste `entrega.tscn` como filho do cliente, ao lado de `pedido.tscn`.
## O recebedor só fica ligado enquanto o cliente tem pedido.


## Saiu um pagamento. Gancho para o cliente ir embora, som, placar, etc.
signal order_paid(correct: bool, amount: int, deliverer: Node)


@export var price_table: PriceTable

@export_group("Comportamento")
## Segundos até o cliente pedir de novo depois de pago. Negativo = não pede de novo
## (o normal no jogo: quem decide é a fila/cliente indo embora).
@export var new_order_delay: float = -1.0
## Faz o sprite do cliente brilhar quando o chef mira nele com um prato na mão.
@export var highlight_owner_sprite: bool = true

@export_group("Texto flutuante")
@export var show_floating_text: bool = true
@export var text_offset: Vector2 = Vector2(0, -30)
@export var correct_color: Color = Color(0.55, 1.0, 0.55)
@export var wrong_color: Color = Color(1.0, 0.6, 0.3)


var order_component: OrderComponent = null


@onready var receiver: DeliveryReceiverComponent = get_node_or_null("Recebedor")


func _ready() -> void:
	if receiver == null:
		push_warning("OrderPaymentComponent (%s): falta o filho 'Recebedor'." % _owner_name())
		return

	order_component = _find_order_component()
	if order_component:
		order_component.order_generated.connect(_on_order_changed.unbind(1))
		order_component.order_cleared.connect(_on_order_changed)

	if highlight_owner_sprite and receiver.highlight_target == null and get_parent():
		receiver.highlight_target = get_parent().get_node_or_null("AnimatedSprite2D") as CanvasItem

	receiver.item_received.connect(_on_item_received)
	_on_order_changed()


# --- API pública ---

## Quanto esta entrega pagaria agora (sem pagar). Útil para UI/tutorial.
func preview_payment(data: ItemData) -> int:
	var order: CustomerOrder = _current_order()
	return price_table.get_payment(order, _is_correct(order, data)) if price_table else 0


# --- Interno ---

func _on_order_changed() -> void:
	if receiver:
		receiver.enabled = order_component == null or order_component.has_order()


func _on_item_received(data: ItemData, deliverer: Node) -> void:
	var order: CustomerOrder = _current_order()
	var correct: bool = _is_correct(order, data)
	var amount: int = price_table.get_payment(order, correct) if price_table else 0

	var wallet: WalletComponent = WalletComponent.find_in(deliverer)
	if wallet == null:
		wallet = WalletComponent.find_default(get_tree())
	if wallet:
		wallet.add(amount)

	if show_floating_text:
		_show_text(correct, amount, wallet)

	if order_component:
		order_component.clear_order()
	order_paid.emit(correct, amount, deliverer)

	if new_order_delay >= 0.0 and order_component:
		get_tree().create_timer(new_order_delay).timeout.connect(_on_reorder_timeout)


func _on_reorder_timeout() -> void:
	if is_instance_valid(order_component) and not order_component.has_order():
		order_component.generate_order()


func _current_order() -> CustomerOrder:
	return order_component.current_order if order_component else null


## Sem OrderComponent (ex.: balcão genérico), qualquer entrega conta como certa.
func _is_correct(order: CustomerOrder, data: ItemData) -> bool:
	if order_component == null:
		return true
	return order != null and order.matches(data)


func _show_text(correct: bool, amount: int, wallet: WalletComponent) -> void:
	var currency: String = wallet.currency_name if wallet else "Almas"
	var message: String = "+%d %s" % [amount, currency]
	if not correct:
		message = "Errado!\n" + message
	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
	FloatingText.spawn(parent, global_position + text_offset,
		message, correct_color if correct else wrong_color)


func _find_order_component() -> OrderComponent:
	var parent: Node = get_parent()
	if parent == null:
		return null
	for child in parent.get_children():
		if child is OrderComponent:
			return child
	return null


func _owner_name() -> String:
	var parent: Node = get_parent()
	return String(parent.name) if parent else String(name)
