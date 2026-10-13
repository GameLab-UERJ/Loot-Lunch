extends InteractableComponent
class_name DeliveryReceiverComponent
## RECEBEDOR de entregas: uma área que aceita itens por DOIS caminhos e avisa quem usa.
##
##   1. Interação (ESPAÇO): o jogador está com o item na mão, de frente para o dono.
##   2. Colisão: um item SOLTO (largado com R, ou no futuro ARREMESSADO) encosta na área.
##
## Os dois caminhos terminam no mesmo lugar: o item é consumido e sai o sinal
## `item_received(data, deliverer)`. O recebedor NÃO sabe o que é pedido nem dinheiro —
## quem decide isso é quem ouve o sinal (ex.: OrderPaymentComponent no cliente).
##
## Reutilizável: cliente, balcão de entrega, lixeira que aceita arremesso, cesta, etc.
##
## Herda InteractableComponent, então o InteractorComponent do chef já enxerga ele
## (camada 4 "interactables") e o destaque (highlight) funciona igual às estações.
##
## Camadas: collision_layer = 8 (interactables), collision_mask = 16 (items).


signal item_received(data: ItemData, deliverer: Node)


@export_group("Entrega")
## Recebe itens SOLTOS que encostam na área (R no chão hoje; arremesso no futuro).
@export var receive_by_collision: bool = true
## Recebe pelo ESPAÇO com o item na mão de quem interage.
@export var receive_by_interaction: bool = true
## Só aceita estes ItemData (.tres). Vazio = aceita qualquer item.
## (Array[Resource] de propósito, mesmo motivo das listas de receitas.)
@export var accepted_items: Array[Resource] = []

@export_group("Silhueta de entrega")
## Quando o chef MIRA neste recebedor com um item aceito na mão (é para cá que o ESPAÇO
## entregaria), o `highlight_target` (sprite do cliente) ganha uma silhueta piscando.
@export var show_delivery_outline: bool = true
@export var delivery_outline_color: Color = Color.WHITE
## Largura em pixels da TELA.
@export var delivery_outline_width: float = 2.0


var _delivery_outline_tween: Tween


func _ready() -> void:
	super._ready()
	monitoring = true
	target_changed.connect(_on_target_changed)


func _exit_tree() -> void:
	_set_delivery_outline(false)


# --- Silhueta de entrega -----------------------------------------------------

func _on_target_changed(targeted: bool, actor: Node) -> void:
	_set_delivery_outline(targeted and show_delivery_outline and can_interact(actor))


func _set_delivery_outline(value: bool) -> void:
	if _delivery_outline_tween:
		_delivery_outline_tween.kill()
		_delivery_outline_tween = null
	# A silhueta do hover (shader) sairia junto: some enquanto a de entrega estiver ligada.
	set_outline_blocked(value)
	if not is_instance_valid(highlight_target):
		return
	if not value:
		SpriteOutline.hide_on(highlight_target)
		return
	var outline: SpriteOutline = SpriteOutline.show_on(highlight_target, delivery_outline_color, delivery_outline_width)
	if outline:
		var dim := Color(delivery_outline_color, delivery_outline_color.a * 0.45)
		# Tween preso no contorno: some junto se o cliente for apagado.
		_delivery_outline_tween = outline.create_tween().set_loops()
		_delivery_outline_tween.tween_property(outline, "color", dim, 0.4)
		_delivery_outline_tween.tween_property(outline, "color", delivery_outline_color, 0.4)


# --- Interação (ESPAÇO) -----------------------------------------------------

## Só "acende" para o chef se ele estiver com um item aceito na mão.
func can_interact(actor: Node) -> bool:
	if not enabled or not receive_by_interaction:
		return false
	var hand: HandComponent = HandComponent.find_in(actor)
	return hand != null and hand.has_item() and can_accept(hand.held_item.data)


func interact(actor: Node) -> bool:
	if not can_interact(actor):
		return false
	var item: CarryableItem = HandComponent.find_in(actor).held_item
	interacted.emit(actor)
	_accept(item, actor)
	return true


# --- Colisão ---------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if not enabled or not receive_by_collision:
		return
	# Varre a área em vez de depender só de area_entered: pega também o item que
	# foi largado já dentro dela (quando ele volta a ser "monitorable").
	for area in get_overlapping_areas():
		var item := area as CarryableItem
		if item == null or item.is_held() or item.is_queued_for_deletion():
			continue
		if not can_accept(item.data):
			continue
		_accept(item, item.last_carrier)
		return  # um item por frame; quem ouve pode desligar o recebedor


# --- API pública -----------------------------------------------------------

func can_accept(data: ItemData) -> bool:
	if not enabled or data == null:
		return false
	if accepted_items.is_empty():
		return true
	for resource in accepted_items:
		var accepted := resource as ItemData
		if accepted == null:
			continue
		if accepted == data or (accepted.id != &"" and accepted.id == data.id):
			return true
	return false


## Entrega direta, sem clique nem colisão (ex.: o futuro projétil chama isso ao acertar).
func receive(item: CarryableItem, deliverer: Node = null) -> bool:
	if item == null or item.is_queued_for_deletion() or not can_accept(item.data):
		return false
	_accept(item, deliverer if deliverer else item.last_carrier)
	return true


func _accept(item: CarryableItem, deliverer: Node) -> void:
	_set_delivery_outline(false)
	var data: ItemData = item.data
	if item.is_held():
		item.current_hand.consume_item()
	else:
		item.queue_free()
	item_received.emit(data, deliverer)
