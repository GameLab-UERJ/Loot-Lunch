extends Node2D
class_name CookingSlot
## UMA "boca" de uma estação que cozinha pelo TEMPO (churrasqueira, fogão, forno...).
##
## Segura um item, conta o tempo e troca a arte sozinho:
##   cru  ->  no ponto  ->  torrado  ->  queima e some.
##
## Componente puro: não conhece o jogador, nem a estação, nem o que é carne.
## Quem usa chama `place()`, `take()` e `discard()`, e escuta os sinais.
## Serve para qualquer coisa que cozinhe com o tempo — basta pendurar numa estação.
##
## Filhos esperados (só a mão é obrigatória, o resto é opcional):
##   Mao     -> HandComponent        onde o item aparece em cima da boca
##   Barra   -> ProgressBarComponent barrinha do tempo (muda de cor por estágio)
##   Toco    -> Sprite2D             cotoco de madeira: "tem espetinho aqui"
##   Efeito  -> SpriteSheetEffect    toca quando o item queima e some


## Ponto do cozimento. RAW = ainda cru, PERFECT = no ponto, BURNT = torrado.
enum Stage { RAW, PERFECT, BURNT }


signal stage_changed(stage: Stage)
signal item_placed(item: CarryableItem)
signal item_taken(item: CarryableItem, stage: Stage)
## O item passou do tempo, queimou e sumiu. (Gancho para a consequência futura.)
signal item_vanished(recipe: CookingRecipe)


@export_group("Cores da barra")
## Enquanto ainda está cru.
@export var raw_color: Color = Color(0.95, 0.72, 0.25, 1.0)
## Quando chega no ponto.
@export var perfect_color: Color = Color(0.35, 0.82, 0.35, 1.0)
## Quando passa do ponto.
@export var burnt_color: Color = Color(0.88, 0.25, 0.22, 1.0)

@export_group("Feedback")
## Esticadinha do item quando ele muda de estágio.
@export var punch_scale: Vector2 = Vector2(1.25, 0.8)
@export var punch_time: float = 0.1


var hand: HandComponent = null
var bar: ProgressBarComponent = null
var toco: CanvasItem = null
var effect: SpriteSheetEffect = null

var _recipe: CookingRecipe = null
var _stage: Stage = Stage.RAW
var _elapsed: float = 0.0
var _perfect_time: float = 10.0
var _burnt_time: float = 20.0
var _vanish_time: float = 25.0


func _ready() -> void:
	hand = HandComponent.find_in(self)
	bar = get_node_or_null("Barra") as ProgressBarComponent
	toco = get_node_or_null("Toco") as CanvasItem
	effect = get_node_or_null("Efeito") as SpriteSheetEffect
	if hand == null:
		push_warning("CookingSlot '%s': nenhum HandComponent filho (nó 'Mao')." % name)
	if toco:
		toco.visible = false
	set_process(false)
	_refresh_bar()


func _process(delta: float) -> void:
	if is_empty():
		_clear()
		return

	_elapsed += delta

	if _elapsed >= _vanish_time:
		_burn_away()
		return
	if _stage != Stage.BURNT and _elapsed >= _burnt_time:
		_set_stage(Stage.BURNT)
	elif _stage == Stage.RAW and _elapsed >= _perfect_time:
		_set_stage(Stage.PERFECT)

	_refresh_bar()


# --- Consultas ---

func is_empty() -> bool:
	return hand == null or hand.is_empty()


func is_occupied() -> bool:
	return not is_empty()


func get_stage() -> Stage:
	return _stage


func get_recipe() -> CookingRecipe:
	return _recipe


## Segundos que o item já passou no fogo.
func get_elapsed() -> float:
	return _elapsed


## Segundos que faltam para o item queimar e sumir.
func get_time_left() -> float:
	return maxf(_vanish_time - _elapsed, 0.0)


## 0.0 = acabou de entrar, 1.0 = queimou.
func get_progress() -> float:
	if is_empty() or _vanish_time <= 0.0:
		return 0.0
	return clampf(_elapsed / _vanish_time, 0.0, 1.0)


func color_for(stage: Stage) -> Color:
	match stage:
		Stage.PERFECT:
			return perfect_color
		Stage.BURNT:
			return burnt_color
		_:
			return raw_color


# --- Ações ---

## Põe o item da mão nesta boca e começa a contar.
## `times` = (segundos para o ponto, para torrar, para sumir).
func place(actor_hand: HandComponent, recipe: CookingRecipe, times: Vector3) -> bool:
	if hand == null or is_occupied() or recipe == null:
		return false
	if actor_hand == null or not actor_hand.has_item():
		return false

	var item: CarryableItem = actor_hand.held_item
	if not actor_hand.transfer_to(hand):
		return false

	_recipe = recipe
	_perfect_time = times.x
	_burnt_time = times.y
	_vanish_time = times.z
	_elapsed = 0.0
	_stage = Stage.RAW

	if toco:
		toco.visible = true
	set_process(true)
	_refresh_bar()
	item_placed.emit(item)
	return true


## Passa o item desta boca para a mão do jogador (mão precisa estar vazia).
func take(actor_hand: HandComponent) -> bool:
	if hand == null or is_empty():
		return false
	if actor_hand == null or actor_hand.has_item():
		return false

	var item: CarryableItem = hand.held_item
	var stage: Stage = _stage
	if not hand.transfer_to(actor_hand):
		return false

	_clear()
	item_taken.emit(item, stage)
	return true


## Joga fora o que estiver na boca (tecla T).
func discard() -> bool:
	if is_empty():
		return false
	hand.consume_item()
	_clear()
	return true


# --- Interno ---

func _set_stage(stage: Stage) -> void:
	_stage = stage
	var data: ItemData = _data_for(stage)
	if data and hand.has_item():
		hand.held_item.data = data
		_punch(hand.held_item)
	stage_changed.emit(stage)


func _data_for(stage: Stage) -> ItemData:
	if _recipe == null:
		return null
	match stage:
		Stage.PERFECT:
			return _recipe.perfect_data
		Stage.BURNT:
			return _recipe.burnt_data
		_:
			return _recipe.input_data


func _burn_away() -> void:
	var recipe: CookingRecipe = _recipe
	if hand:
		hand.consume_item()
	if effect:
		effect.play_once()
	_clear()
	item_vanished.emit(recipe)


func _clear() -> void:
	_recipe = null
	_stage = Stage.RAW
	_elapsed = 0.0
	set_process(false)
	if toco:
		toco.visible = false
	_refresh_bar()


func _refresh_bar() -> void:
	if bar == null:
		return
	var occupied: bool = is_occupied()
	bar.set_bar_visible(occupied)
	if not occupied:
		bar.set_progress(0.0)
		return
	bar.fill_color = color_for(_stage)
	bar.set_progress(get_progress())


func _punch(item: CarryableItem) -> void:
	if not is_instance_valid(item) or punch_time <= 0.0:
		return
	item.scale = punch_scale
	create_tween().tween_property(item, "scale", Vector2.ONE, punch_time)
