extends BossMinigame
class_name EntregaVip
## FINALIZAÇÃO da boss fight: A ENTREGA AO VIP.
##
## O chef (o MESMO chef.tscn do restaurante: WASD + ESPAÇO para tudo) começa com o prato
## completo na mão e precisa CAMINHAR até o VIP e entregar (ESPAÇO de frente para ele). O VIP usa o DeliveryReceiverComponent do restaurante, então
## nenhuma regra nova de entrega foi criada.


@export var chef: Chef
@export var vip: VipNpc
## carryable_item.tscn do restaurante.
@export var item_scene: PackedScene
## prato_vip.tres
@export var dish_data: ItemData


func _ready() -> void:
	super._ready()
	chef.can_control = false
	vip.dish_received.connect(_on_dish_received)


func _on_begin() -> void:
	chef.can_control = true
	var dish := item_scene.instantiate() as CarryableItem
	dish.data = dish_data
	chef.hand_component.hold(dish)
	vip.say("Estou esperando...")
	popup(chef.global_position + Vector2(0, -30), "Leve o prato ao VIP!", Color(1.0, 0.9, 0.6))


func _on_dish_received(data: ItemData, _deliverer: Node) -> void:
	if not running or data == null or data.id != dish_data.id:
		return
	chef.can_control = false
	vip.celebrate()
	finish(true, {"label": "Prato entregue ao VIP!", "quality": 1.0})
