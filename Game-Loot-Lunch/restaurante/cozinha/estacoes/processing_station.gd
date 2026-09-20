extends KitchenStation
class_name ProcessingStation
## Estação que TRANSFORMA um ingrediente em outro por etapas (tábua de corte, e no futuro
## fogão, liquidificador, pilão...). Quais itens ela aceita é DADO: a lista `recipes`.
##
## Fluxo (tecla B, `chef_interact`):
##   1. B com o ingrediente certo na mão  -> o item vai para cima da estação e a tarefa começa.
##   2. B de novo, N vezes                -> cada toque conta uma etapa e enche a barrinha.
##   3. na última etapa                   -> o item vira o `output_data` da receita.
##   4. B com a mão vazia                 -> pega o item pronto de volta.
##
## REGRA: começou, tem que terminar. Enquanto a tarefa está em andamento a estação só
## aceita B para avançar o corte — não devolve o item nem aceita outro ingrediente.
##
## Filhos esperados: Sprite2D, CollisionShape2D, InteractableComponent, ItemSlot (HandComponent),
## ProgressComponent e, opcionais, BarraProgresso (ProgressBarComponent) e EfeitoCorte (SpriteSheetEffect).


signal processing_started(item: CarryableItem, recipe: ProcessingRecipe)
signal step_done(current_steps: int, total_steps: int)
signal processing_finished(item: CarryableItem)


## Receitas aceitas (arraste os .tres de ProcessingRecipe aqui).
@export var recipes: Array[Resource] = []

@export_group("Feedback")
@export var show_progress_bar: bool = true
## Esticadinha do item a cada etapa (feedback de "faca batendo").
@export var punch_scale: Vector2 = Vector2(1.18, 0.82)
@export var punch_time: float = 0.08


@onready var slot: HandComponent = $ItemSlot
@onready var progress: ProgressComponent = $ProgressComponent
@onready var progress_bar: ProgressBarComponent = get_node_or_null("BarraProgresso")
@onready var finish_effect: SpriteSheetEffect = get_node_or_null("EfeitoCorte")


var _recipe: ProcessingRecipe = null


func _ready() -> void:
	super()
	progress.step_added.connect(_on_step_added)
	progress.completed.connect(_on_progress_completed)
	_refresh_bar()


## Tem uma tarefa em andamento? (item em cima, ainda não terminado)
func is_busy() -> bool:
	return _recipe != null


## Tem um item pronto esperando para ser retirado?
func has_finished_item() -> bool:
	return not is_busy() and slot.has_item()


## Procura a receita para um ingrediente. Retorna null se a estação não aceita esse item.
func find_recipe(data: ItemData) -> ProcessingRecipe:
	for entry in recipes:
		var recipe := entry as ProcessingRecipe
		if recipe and recipe.matches(data):
			return recipe
	return null


func _interact(_actor: Node, actor_hand: HandComponent) -> void:
	if actor_hand == null:
		return

	# Tarefa em andamento: B só corta. Não devolve o item até terminar.
	if is_busy():
		_do_step()
		return

	# Item pronto em cima da estação: B com a mão vazia retira.
	if slot.has_item():
		slot.transfer_to(actor_hand)
		_refresh_bar()
		return

	_try_place(actor_hand)


## Coloca o ingrediente da mão na estação e começa a tarefa. Retorna true se aceitou.
func _try_place(actor_hand: HandComponent) -> bool:
	if not actor_hand.has_item():
		return false

	var item: CarryableItem = actor_hand.held_item
	var recipe: ProcessingRecipe = find_recipe(item.data)
	if recipe == null:
		return false  # ingrediente que esta estação não prepara
	if not actor_hand.transfer_to(slot):
		return false

	_recipe = recipe
	progress.begin(recipe.required_steps)
	_refresh_bar()
	processing_started.emit(item, recipe)
	return true


func _do_step() -> void:
	_punch_item()
	progress.add_step()


func _on_step_added(current_steps: int, total_steps: int) -> void:
	_refresh_bar()
	step_done.emit(current_steps, total_steps)


func _on_progress_completed() -> void:
	var item: CarryableItem = slot.held_item
	if is_instance_valid(item) and _recipe and _recipe.output_data:
		item.data = _recipe.output_data  # troca a arte e os dados do item

	_recipe = null
	progress.reset()
	_refresh_bar()

	if finish_effect:
		finish_effect.play_once()
	processing_finished.emit(item)


func _punch_item() -> void:
	var item: CarryableItem = slot.held_item
	if not is_instance_valid(item) or punch_time <= 0.0:
		return
	item.scale = punch_scale
	create_tween().tween_property(item, "scale", Vector2.ONE, punch_time)


func _refresh_bar() -> void:
	if progress_bar == null:
		return
	progress_bar.set_progress(progress.get_progress())
	progress_bar.set_bar_visible(show_progress_bar and is_busy())
