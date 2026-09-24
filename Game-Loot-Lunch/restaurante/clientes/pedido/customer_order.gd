extends RefCounted
class_name CustomerOrder
## UM pedido já sorteado: qual opção do cardápio + em que ponto o cliente quer.
## É criado pelo OrderComponent. Não é salvo em disco (por isso RefCounted, não Resource).


enum CookPoint { PERFECT, BURNT }


var option: OrderOption
var cook_point: CookPoint = CookPoint.PERFECT


func _init(p_option: OrderOption = null, p_cook_point: CookPoint = CookPoint.PERFECT) -> void:
	option = p_option
	cook_point = p_cook_point


func get_icons() -> Array:
	if option == null:
		return []
	return option.icons


## O item que o jogador precisa entregar (ex.: espetinho_misto_perfeito.tres).
func get_expected_item() -> ItemData:
	return option.get_item_for(cook_point) if option else null


## Este item resolve o pedido? Compara pelo recurso e, se não bater, pelo `id`
## (mesma regra das receitas).
func matches(data: ItemData) -> bool:
	var expected: ItemData = get_expected_item()
	if data == null or expected == null:
		return false
	if data == expected:
		return true
	return data.id != &"" and data.id == expected.id


func is_burnt() -> bool:
	return cook_point == CookPoint.BURNT


func describe() -> String:
	var name_text: String = option.display_name if option else "?"
	return "%s (%s)" % [name_text, "torrado" if is_burnt() else "no ponto"]
