extends Resource
class_name CookingRecipe
## Receita de COZIMENTO: um item cru vai mudando sozinho com o TEMPO na estação
## (churrasqueira, fogão, forno...). Cru -> no ponto -> torrado -> some.
##
## Prima da ProcessingRecipe (lá quem faz o progresso é o jogador apertando B)
## e da AssemblyRecipe (lá vários itens viram um). Aqui quem trabalha é o relógio.
##
## Crie um .tres por receita: botão direito no FileSystem > New Resource > CookingRecipe.
## Ex.: espetinho_carne_cru -> espetinho_carne_perfeito -> espetinho_carne_torrado.


## Item que a estação aceita (o espetinho cru).
@export var input_data: ItemData
## Como fica quando chega no ponto certo.
@export var perfect_data: ItemData
## Como fica quando passa do ponto.
@export var burnt_data: ItemData

@export_group("Tempos (s)")
## Segundos até ficar no ponto. <= 0 usa o tempo da estação.
@export var perfect_time: float = -1.0
## Segundos até torrar. <= 0 usa o tempo da estação.
@export var burnt_time: float = -1.0
## Segundos até o item queimar de vez e sumir. <= 0 usa o tempo da estação.
@export var vanish_time: float = -1.0


## A receita serve para este item? Compara pelo recurso e, se não bater, pelo `id`.
## (Mesma regra da ProcessingRecipe.)
func matches(data: ItemData) -> bool:
	if data == null or input_data == null:
		return false
	if data == input_data:
		return true
	return data.id != &"" and data.id == input_data.id


## Tempos finais desta receita: os que ela definir, senão os `fallback` da estação.
## Retorna (ponto, torrado, sumir), sempre em ordem crescente.
func resolve_times(fallback: Vector3) -> Vector3:
	var perfect: float = perfect_time if perfect_time > 0.0 else fallback.x
	var burnt: float = burnt_time if burnt_time > 0.0 else fallback.y
	var vanish: float = vanish_time if vanish_time > 0.0 else fallback.z
	burnt = maxf(burnt, perfect)
	vanish = maxf(vanish, burnt)
	return Vector3(perfect, burnt, vanish)
