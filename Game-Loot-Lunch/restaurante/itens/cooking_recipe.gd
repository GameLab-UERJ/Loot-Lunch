extends Resource
class_name CookingRecipe
## Receita de COZIMENTO: um item cru vai mudando sozinho com o TEMPO na estação
## (churrasqueira, fogão, forno...). Cru -> no ponto -> torrado -> some.
##
## Prima da ProcessingRecipe (lá quem faz o progresso é o jogador clicando com o botão direito)
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

@export_group("Arte girando no fogo")
## Linha (contando de 1) da spritesheet de "espetinho girando" com este item CRU.
## As duas linhas seguintes são o NO PONTO e o TORRADO. 0 = usa a arte parada do item.
## Ex.: carne = 1, cogumelo = 4, misto = 7.
@export_range(0, 64) var spin_row: int = 0

@export_group("Balão na estação")
## Ícones do balão que aparece em cima da boca enquanto este item assa.
## 1 ícone = inteiro; 2 = metade/metade, da esquerda para a direita
## (ex.: misto = [cogumelo, carne]). Vazio = sem balão.
@export var bubble_icons: Array[Texture2D] = []

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


## Linha da arte girando para o ponto dado (0 = cru, 1 = no ponto, 2 = torrado).
## Retorna 0 se esta receita não tem arte girando.
func get_spin_row(stage: int) -> int:
	if spin_row <= 0:
		return 0
	return spin_row + clampi(stage, 0, 2)


## Tempos finais desta receita: os que ela definir, senão os `fallback` da estação.
## Retorna (ponto, torrado, sumir), sempre em ordem crescente.
func resolve_times(fallback: Vector3) -> Vector3:
	var perfect: float = perfect_time if perfect_time > 0.0 else fallback.x
	var burnt: float = burnt_time if burnt_time > 0.0 else fallback.y
	var vanish: float = vanish_time if vanish_time > 0.0 else fallback.z
	burnt = maxf(burnt, perfect)
	vanish = maxf(vanish, burnt)
	return Vector3(perfect, burnt, vanish)
