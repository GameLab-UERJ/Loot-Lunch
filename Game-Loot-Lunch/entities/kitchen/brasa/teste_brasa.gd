extends Node2D
## Cena de teste da BRASA (churrasqueira-chama que anda), com 2 jogadores no mesmo teclado.
##
##   Jogador 1 (chef):  WASD anda · ESPAÇO faz tudo · Shift dash · R descarta
##   Jogador 2 (brasa): SETAS anda
##   G = espetinho cru na mão do chef · T = espetinho no ponto · Y = espetinho torrado
##
## O chef desta cena usa um ActionInputComponent (WASD) no lugar do InputComponent
## padrão (WASD + setas), senão as setas mexeriam os dois ao mesmo tempo.


const CARRYABLE_ITEM_SCENE: PackedScene = preload("res://entities/items/restaurant/carryable_item.tscn")
const DEBUG_ITEMS: Dictionary = {
	KEY_G: preload("res://entities/items/restaurant/dados/espetinho_misto_cru.tres"),
	KEY_T: preload("res://entities/items/restaurant/dados/espetinho_carne_perfeito.tres"),
	KEY_Y: preload("res://entities/items/restaurant/dados/espetinho_cogumelo_torrado.tres"),
}


@onready var chef: Chef = $Chef
@onready var brasa: Brasa = $Brasa
@onready var items_container: Node2D = $ItensNoChao
@onready var status_label: Label = $Interface/Status


func _process(_delta: float) -> void:
	var lines: PackedStringArray = []
	lines.append("Brasa: %s" % brasa.state_machine.states.find_key(brasa.state_machine.state))
	for slot in brasa.station.get_slots():
		if slot.is_empty():
			lines.append("  %s: vazia" % slot.name)
		else:
			var stage: String = ["cru", "no ponto", "torrado"][slot.get_stage()]
			lines.append("  %s: %s (%.1f s)" % [slot.name, stage, slot.get_elapsed()])
	status_label.text = "\n".join(lines)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if DEBUG_ITEMS.has(key.physical_keycode):
		_give_to_chef(DEBUG_ITEMS[key.physical_keycode])
		get_viewport().set_input_as_handled()


func _give_to_chef(data: ItemData) -> void:
	if chef.hand_component.has_item():
		return
	var item: CarryableItem = CARRYABLE_ITEM_SCENE.instantiate()
	item.data = data
	items_container.add_child(item)
	item.global_position = chef.global_position
	chef.hand_component.hold(item)
