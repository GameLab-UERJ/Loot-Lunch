class_name Recipe
extends Resource

## Nome da receita (ex: "Carne")
@export var recipe_name: String = ""

## Cenas dos ingredientes necessários (ordem não importa)
@export var ingredients: Array[PackedScene] = []

## Cena do Item resultado
@export var result_scene: PackedScene

## Quantidade do item resultado
@export var result_count: int = 1


## Verifica se um grid 3x3 de itens bate com esta receita
func matches(grid_items: Array[Item]) -> bool:
	# Conta quantos itens tem no grid (ignora vazios)
	var grid_has: Array[Item] = []
	for item in grid_items:
		if item:
			grid_has.append(item)
	
	# Precisa ter exatamente o mesmo número de ingredientes
	if grid_has.size() != ingredients.size():
		return false
	
	# Converte ingredientes da receita para nomes
	var needed_names: Array[String] = []
	for ing_scene in ingredients:
		var ing_item = ing_scene.instantiate() as Item
		needed_names.append(ing_item.item_name)
		ing_item.queue_free()
	
	# Converte itens do grid para nomes
	var grid_names: Array[String] = []
	for item in grid_has:
		grid_names.append(item.item_name)
	
	# Ordena os dois arrays e compara
	needed_names.sort()
	grid_names.sort()
	
	return needed_names == grid_names
