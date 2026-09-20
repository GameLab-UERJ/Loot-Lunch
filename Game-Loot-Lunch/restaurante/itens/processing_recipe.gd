extends Resource
class_name ProcessingRecipe
## Receita de transformação de UM item em outro numa estação de preparo
## (tábua de corte, fogão, liquidificador...).
##
## Crie um .tres por receita: botão direito no FileSystem > New Resource > ProcessingRecipe.
## Ex.: carne_bruta -> carne_cortada em 5 etapas.


## Item que a estação aceita.
@export var input_data: ItemData
## Item que sai no fim.
@export var output_data: ItemData
## Quantas vezes o jogador precisa apertar a tecla de interação.
@export_range(1, 50) var required_steps: int = 5


## A receita serve para este item? Compara pelo recurso e, se não bater, pelo `id`.
func matches(data: ItemData) -> bool:
	if data == null or input_data == null:
		return false
	if data == input_data:
		return true
	return data.id != &"" and data.id == input_data.id
