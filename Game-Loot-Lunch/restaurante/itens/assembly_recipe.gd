extends Resource
class_name AssemblyRecipe
## Receita de MONTAGEM: um CONJUNTO de itens vira UM item novo.
## Ex.: carne_cortada + carne_cortada -> espetinho_carne_cru.
##
## Irmã da ProcessingRecipe: lá UM item vira outro apertando N vezes,
## aqui VÁRIOS itens juntos viram um só.
##
## Crie um .tres por receita: botão direito no FileSystem > New Resource > AssemblyRecipe.
## A ORDEM NÃO importa: carne+cogumelo e cogumelo+carne fecham a mesma receita (misto).
## Para pedir 2x o mesmo ingrediente, coloque ele duas vezes na lista `inputs`.


## Itens necessários (arraste os ItemData .tres).
@export var inputs: Array[Resource] = []
## Item que sai no fim.
@export var output_data: ItemData


## Chave de comparação de um item: o `id` do ItemData (ou o caminho do recurso, se não tiver id).
static func key_of(data: ItemData) -> StringName:
	if data == null:
		return &""
	if data.id != &"":
		return data.id
	return StringName(data.resource_path)


## Quantos itens esta receita pede.
func get_size() -> int:
	return get_input_keys().size()


## O conjunto `keys` fecha EXATAMENTE esta receita?
func matches(keys: Array) -> bool:
	var needed: Array = get_input_keys()
	return keys.size() == needed.size() and _fits_in(keys, needed)


## O conjunto `keys` (montagem pela metade) ainda CABE nesta receita?
## Usado para decidir se a estação aceita mais um ingrediente.
func accepts(keys: Array) -> bool:
	var needed: Array = get_input_keys()
	return keys.size() <= needed.size() and _fits_in(keys, needed)


func get_input_keys() -> Array:
	var keys: Array = []
	for entry in inputs:
		var data := entry as ItemData
		if data:
			keys.append(key_of(data))
	return keys


## `keys` cabe dentro de `needed` contando repetições (2 carnes != 1 carne).
func _fits_in(keys: Array, needed: Array) -> bool:
	var pool: Array = needed.duplicate()
	for key in keys:
		var index: int = pool.find(key)
		if index == -1:
			return false
		pool.remove_at(index)
	return true
