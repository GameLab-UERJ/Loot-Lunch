extends Area2D
class_name CarryableItem
## Qualquer item que pode ser carregado por um HandComponent.
## Quando está numa mão, deixa de ser detectável (monitorable = false),
## então o InteractorComponent só enxerga itens soltos no chão.
##
## Camada sugerida: collision_layer = 16 (camada 5 "items"), mask = 0.


signal picked_up(hand: HandComponent)
signal dropped


@export var data: ItemData: set = set_data


var current_hand: HandComponent = null
## Dono da ÚLTIMA mão que segurou este item (ex.: o Chef que largou/arremessou).
## Usado pela entrega para saber quem recebe o pagamento.
var last_carrier: Node = null


@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")


func _ready() -> void:
	_apply_data()


func set_data(value: ItemData) -> void:
	data = value
	if is_node_ready():
		_apply_data()


func can_be_picked_up() -> bool:
	return current_hand == null


func is_held() -> bool:
	return current_hand != null


func get_hold_offset() -> Vector2:
	return data.hold_offset if data else Vector2.ZERO


## Chamado pelo HandComponent. Não chame diretamente.
func notify_held(hand: HandComponent) -> void:
	current_hand = hand
	set_deferred("monitorable", false)
	picked_up.emit(hand)


## Chamado pelo HandComponent. Não chame diretamente.
func notify_released() -> void:
	if current_hand:
		last_carrier = current_hand.get_parent()
	current_hand = null
	set_deferred("monitorable", true)
	dropped.emit()


func _apply_data() -> void:
	if sprite:
		sprite.texture = data.texture if data else null
		sprite.scale = data.sprite_scale if data else Vector2.ONE
	queue_redraw()


func _draw() -> void:
	if sprite and sprite.texture:
		return
	var color: Color = data.placeholder_color if data else Color.WHITE
	draw_circle(Vector2.ZERO, 8.0, color)
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 24, Color(0, 0, 0, 0.6), 1.0)
