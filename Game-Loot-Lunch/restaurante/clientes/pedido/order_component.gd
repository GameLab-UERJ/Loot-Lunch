extends Node2D
class_name OrderComponent
## PEDIDO do cliente. Sorteia o que ele quer e mostra no balão de pensamento
## quando o jogador chega perto.
##
## Mesma regra de sempre: **o componente é cena, o cardápio é dado.**
## O OrderComponent não sabe o que é carne nem cogumelo — ele só lê uma lista
## de OrderOption (.tres) e sorteia pelos pesos.
##
## Junta dois componentes genéricos (filhos da cena pedido.tscn):
##   ThoughtBubble -> ThoughtBubbleComponent (só desenha)
##   Proximity     -> ProximityComponent     (só detecta o jogador)
## Qualquer um deles pode faltar: sem Proximity o balão fica sempre visível.
##
## Uso: arraste `pedido.tscn` como filho de qualquer cliente. Pronto.


signal order_generated(order: CustomerOrder)
signal order_cleared


@export_group("Cardápio")
## Opções sorteadas (arquivos OrderOption .tres).
## Chance de cada uma = peso dela / soma dos pesos.
@export var options: Array[Resource] = []
## Chance (0 a 1) de o cliente querer o espetinho TORRADO. O resto quer NO PONTO.
@export_range(0.0, 1.0, 0.01) var burnt_chance: float = 0.5

@export_group("Aura (ponto do espetinho)")
@export var perfect_aura_color: Color = Color(0.3, 1.0, 0.35, 1.0)
@export var burnt_aura_color: Color = Color(1.0, 0.2, 0.15, 1.0)

@export_group("Comportamento")
## Sorteia um pedido assim que o cliente entra na cena.
@export var generate_on_ready: bool = true
## true: o balão só aparece com o jogador perto. false: sempre visível enquanto houver pedido.
@export var show_only_when_near: bool = true
## Escreve o pedido sorteado no Output (útil na cena de teste).
@export var debug_print: bool = false


var current_order: CustomerOrder = null


@onready var bubble: ThoughtBubbleComponent = get_node_or_null("ThoughtBubble")
@onready var proximity: ProximityComponent = get_node_or_null("Proximity")


func _ready() -> void:
	if proximity:
		proximity.presence_changed.connect(_on_presence_changed)
	if generate_on_ready:
		generate_order()
	else:
		_refresh_bubble()


# --- API pública ---

## Sorteia um pedido novo, aplica no balão e retorna ele.
func generate_order() -> CustomerOrder:
	var order: CustomerOrder = roll_order()
	if order == null:
		push_warning("OrderComponent (%s): nenhuma OrderOption válida em 'options'." % _owner_name())
		return null
	set_order(order)
	return order


## Só SORTEIA (não mexe no balão nem no pedido atual). Útil para testes e estatística.
func roll_order() -> CustomerOrder:
	var option: OrderOption = pick_option(options)
	if option == null:
		return null
	var point: CustomerOrder.CookPoint = CustomerOrder.CookPoint.PERFECT
	if randf() < burnt_chance:
		point = CustomerOrder.CookPoint.BURNT
	return CustomerOrder.new(option, point)


## Define o pedido na mão (ex.: tutorial, fase com pedido fixo).
func set_order(order: CustomerOrder) -> void:
	current_order = order
	if bubble and order:
		bubble.set_icons(order.get_icons())
		bubble.set_aura(get_aura_color(order.cook_point))
	_refresh_bubble()
	order_generated.emit(order)
	if debug_print and order:
		print("[Pedido] %s quer: %s" % [_owner_name(), order.describe()])


## Pedido atendido / cliente foi embora.
func clear_order() -> void:
	current_order = null
	_refresh_bubble()
	order_cleared.emit()


func has_order() -> bool:
	return current_order != null


## Este item resolve o pedido atual? Gancho pronto para a entrega.
func is_satisfied_by(data: ItemData) -> bool:
	return has_order() and current_order.matches(data)


func get_aura_color(cook_point: int) -> Color:
	if cook_point == CustomerOrder.CookPoint.BURNT:
		return burnt_aura_color
	return perfect_aura_color


## Sorteio por peso. `list` pode ter qualquer Resource: só OrderOption com peso > 0 conta.
static func pick_option(list: Array) -> OrderOption:
	var valid: Array[OrderOption] = []
	var total: float = 0.0
	for resource in list:
		var option := resource as OrderOption
		if option and option.weight > 0.0:
			valid.append(option)
			total += option.weight
	if valid.is_empty():
		return null

	var roll: float = randf() * total
	for option in valid:
		roll -= option.weight
		if roll < 0.0:
			return option
	return valid.back()


# --- Interno ---

func _on_presence_changed(_is_present: bool) -> void:
	_refresh_bubble()


func _refresh_bubble() -> void:
	if bubble == null:
		return
	var player_near: bool = proximity == null or proximity.has_target()
	if has_order() and (player_near or not show_only_when_near):
		bubble.appear()
	else:
		bubble.disappear()


func _owner_name() -> String:
	var parent: Node = get_parent()
	return String(parent.name) if parent else String(name)
