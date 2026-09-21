extends KitchenStation
class_name AssemblyStation
## Estação de MONTAGEM: recebe VÁRIOS itens em slots empilhados (de baixo para cima) e,
## quando o conjunto fecha uma receita, entrega UM item novo.
## Ex.: raiz de espeto -> 2 itens cortados -> espetinho.
##
## Quais itens ela aceita é DADO: a lista `recipes` (AssemblyRecipe). A estação não sabe
## o que é carne nem cogumelo. Quantos itens cabem também é DADO: é o número de
## HandComponents dentro do nó `Slots` (ordem da árvore = de baixo para cima).
##
## Fluxo:
##   1. B com um ingrediente aceito na mão -> o item é fincado no primeiro slot livre.
##   2. Repete até encher os slots.
##   3. B com a MÃO VAZIA e o conjunto fechando uma receita -> o jogador leva o item pronto
##      e a estação entra em cooldown.
##   4. T (ação secundária) perto dela -> apaga o que estiver montado, toca o efeito de
##      fogo e entra em cooldown.
##   Ao fim de qualquer cooldown toca o efeito de "pronto" e ela volta a aceitar itens.
##
## Filhos esperados: Sprite2D, CollisionShape2D, InteractableComponent, Slots (com
## HandComponents dentro), CooldownComponent e, opcionais, BarraProgresso
## (ProgressBarComponent), EfeitoReset e EfeitoPronto (SpriteSheetEffect).


signal item_placed(item: CarryableItem, total: int)
signal assembly_completed(recipe: AssemblyRecipe)
signal item_collected(data: ItemData)
signal cleared
signal cooldown_started(duration: float)
signal cooldown_ended


## Receitas aceitas (arraste os .tres de AssemblyRecipe aqui).
@export var recipes: Array[Resource] = []
## Cena genérica do item carregável, usada para criar o item pronto (carryable_item.tscn).
@export var item_scene: PackedScene

@export_group("Cooldown")
## Espera depois que o jogador COLETA o item montado. <= 0 usa o CooldownComponent.duration.
@export var collect_cooldown: float = 3.0
## Espera depois que o jogador RESETA a estação (tecla T). <= 0 usa o CooldownComponent.duration.
@export var reset_cooldown: float = 3.0

@export_group("Feedback")
## Cor do sprite enquanto a estação está em cooldown.
@export var cooldown_modulate: Color = Color(0.45, 0.45, 0.45, 1.0)
@export var show_progress_bar: bool = true
## Esticadinha do item ao ser fincado.
@export var punch_scale: Vector2 = Vector2(1.2, 0.8)
@export var punch_time: float = 0.08


@onready var slots_root: Node = get_node_or_null("Slots")
@onready var cooldown: CooldownComponent = get_node_or_null("CooldownComponent")
@onready var visual: CanvasItem = get_node_or_null("Sprite2D")
@onready var progress_bar: ProgressBarComponent = get_node_or_null("BarraProgresso")
@onready var reset_effect: SpriteSheetEffect = get_node_or_null("EfeitoReset")
@onready var ready_effect: SpriteSheetEffect = get_node_or_null("EfeitoPronto")


var _slots: Array[HandComponent] = []


func _ready() -> void:
	super()
	_collect_slots()
	if cooldown:
		cooldown.finished.connect(_on_cooldown_finished)
	set_process(false)
	_refresh_bar()


func _process(_delta: float) -> void:
	_refresh_bar()


# --- Consultas ---

## Quantos itens cabem (número de HandComponents em `Slots`).
func get_capacity() -> int:
	return _slots.size()


## Quantos itens já estão fincados.
func get_count() -> int:
	var total: int = 0
	for slot in _slots:
		if slot.has_item():
			total += 1
	return total


func is_empty() -> bool:
	return get_count() == 0


func is_full() -> bool:
	return get_capacity() > 0 and get_count() == get_capacity()


func is_on_cooldown() -> bool:
	return cooldown != null and not cooldown.is_ready()


## Está cheio E o conjunto fecha uma receita? (pronto para o jogador coletar)
func is_complete() -> bool:
	return find_recipe() != null


## Receita fechada pelo conjunto atual. null se ainda falta item ou se a combinação não existe.
func find_recipe() -> AssemblyRecipe:
	if not is_full():
		return null
	var keys: Array = _current_keys()
	for entry in recipes:
		var recipe := entry as AssemblyRecipe
		if recipe and recipe.matches(keys):
			return recipe
	return null


## Este ingrediente cabe no que está sendo montado?
func can_accept(data: ItemData) -> bool:
	if data == null or is_full() or is_on_cooldown():
		return false
	var keys: Array = _current_keys()
	keys.append(AssemblyRecipe.key_of(data))
	for entry in recipes:
		var recipe := entry as AssemblyRecipe
		if recipe and recipe.accepts(keys):
			return true
	return false


# --- Interação ---

func _interact(_actor: Node, actor_hand: HandComponent) -> void:
	if actor_hand == null or is_on_cooldown():
		return
	if actor_hand.has_item():
		place_item(actor_hand)
	else:
		collect_item(actor_hand)


## Ação secundária (tecla T): limpa o que estiver montado.
func _alt_interact(_actor: Node, _actor_hand: HandComponent) -> void:
	reset_station()


## Finca o item da mão no primeiro slot livre. Retorna true se aceitou.
func place_item(actor_hand: HandComponent) -> bool:
	var slot: HandComponent = _first_empty_slot()
	if slot == null or not actor_hand.has_item():
		return false

	var item: CarryableItem = actor_hand.held_item
	if not can_accept(item.data):
		return false
	if not actor_hand.transfer_to(slot):
		return false

	_punch(item)
	item_placed.emit(item, get_count())

	var recipe: AssemblyRecipe = find_recipe()
	if recipe:
		assembly_completed.emit(recipe)
	return true


## Entrega o item montado na mão do jogador (mão precisa estar vazia) e entra em cooldown.
func collect_item(actor_hand: HandComponent) -> bool:
	if actor_hand == null or actor_hand.has_item():
		return false

	var recipe: AssemblyRecipe = find_recipe()
	if recipe == null or recipe.output_data == null or item_scene == null:
		return false

	var node: Node = item_scene.instantiate()
	var item: CarryableItem = node as CarryableItem
	if item == null:
		push_error("AssemblyStation: item_scene precisa ter um CarryableItem na raiz.")
		node.queue_free()
		return false

	item.data = recipe.output_data
	if not actor_hand.hold(item):
		item.queue_free()
		return false

	_clear_slots()
	item_collected.emit(recipe.output_data)
	_start_cooldown(collect_cooldown)
	return true


## Apaga os itens montados, toca o efeito de reset e entra em cooldown.
func reset_station() -> bool:
	if is_on_cooldown() or is_empty():
		return false
	if reset_effect:
		reset_effect.play_once()
	_clear_slots()
	cleared.emit()
	_start_cooldown(reset_cooldown)
	return true


# --- Interno ---

func _collect_slots() -> void:
	_slots.clear()
	var root: Node = slots_root if slots_root else self
	for child in root.get_children():
		var slot := child as HandComponent
		if slot:
			_slots.append(slot)
	if _slots.is_empty():
		push_warning("AssemblyStation '%s': nenhum HandComponent dentro de 'Slots'." % name)


func _first_empty_slot() -> HandComponent:
	for slot in _slots:
		if slot.is_empty():
			return slot
	return null


func _current_keys() -> Array:
	var keys: Array = []
	for slot in _slots:
		if slot.has_item() and slot.held_item.data:
			keys.append(AssemblyRecipe.key_of(slot.held_item.data))
	return keys


func _clear_slots() -> void:
	for slot in _slots:
		slot.consume_item()


func _start_cooldown(time: float) -> void:
	if cooldown == null:
		return
	interactable.enabled = false
	interactable.set_focused(false)
	if visual:
		visual.self_modulate = cooldown_modulate
	set_process(show_progress_bar)
	cooldown_started.emit(time if time > 0.0 else cooldown.duration)
	cooldown.start(time)
	_refresh_bar()


func _on_cooldown_finished() -> void:
	interactable.enabled = true
	if visual:
		visual.self_modulate = Color.WHITE
	set_process(false)
	_refresh_bar()
	if ready_effect:
		ready_effect.play_once()
	cooldown_ended.emit()


func _punch(item: CarryableItem) -> void:
	if not is_instance_valid(item) or punch_time <= 0.0:
		return
	item.scale = punch_scale
	create_tween().tween_property(item, "scale", Vector2.ONE, punch_time)


func _refresh_bar() -> void:
	if progress_bar == null:
		return
	progress_bar.set_progress(cooldown.get_progress() if cooldown else 1.0)
	progress_bar.set_bar_visible(show_progress_bar and is_on_cooldown())
