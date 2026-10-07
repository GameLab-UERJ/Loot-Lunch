extends KitchenStation
class_name CookingStation
## Estação que COZINHA com o tempo (churrasqueira, fogão, forno...).
##
## Mesma regra de sempre: **a estação é cena, o cozimento é dado.** A churrasqueira
## não sabe o que é carne nem cogumelo — ela só lê uma lista de `CookingRecipe`.
## Por isso ela aceita SÓ os itens que têm receita (os três espetinhos crus) e
## recusa qualquer outra coisa na mão do jogador.
##
## Quantas bocas ela tem também é dado: é o número de `CookingSlot` dentro do nó `Bocas`
## (ordem da árvore = ordem em que são ocupadas).
##
## Fluxo:
##   1. ESPAÇO com um espetinho cru na mão -> vai para a primeira boca livre.
##   2. Cada boca conta o tempo sozinha e troca a arte: cru -> no ponto -> torrado
##      (o espetinho aparece GIRANDO no fogo, linha certa da spritesheet).
##   3. ESPAÇO com a MÃO VAZIA -> tira o espetinho da boca mais perto do
##      cursor (ou do jogador, se o mouse não está em cima da estação),
##      no ponto em que ele estiver (são 3 resultados possíveis).
##      Antes de apertar, o espetinho que vai sair já fica com a SILHUETA branca
##      (e o balão dele realçado), em vez da churrasqueira inteira.
##   4. Passou do tempo -> o espetinho queima, some e a estação avisa por
##      `item_vanished` (gancho para a consequência futura).
##   5. R (ação secundária) -> joga fora o espetinho da boca mais perto (o destacado).
##
## Cada boca mostra um BALÃO com o que está assando (carne, cogumelo ou metade/metade
## no misto). Os ícones vêm da receita (`CookingRecipe.bubble_icons`).
##
## Filhos esperados: AnimatedSprite2D (ou Sprite2D), CollisionShape2D, InteractableComponent e
## `Bocas` (com um `CookingSlot` para cada boca). Opcional: `CookingStationFSM`, que troca
## a animação da estação (vazia / assando / alerta / risada).


signal item_placed(slot: CookingSlot, item: CarryableItem)
## `stage` é um CookingSlot.Stage (0 = cru, 1 = no ponto, 2 = torrado).
signal item_collected(slot: CookingSlot, item: CarryableItem, stage: int)
## Um espetinho passou do tempo, queimou e sumiu.
signal item_vanished(slot: CookingSlot, recipe: CookingRecipe)


## Receitas aceitas (arraste os .tres de CookingRecipe aqui).
@export var recipes: Array[Resource] = []

@export_group("Tempos padrão (s)")
## Até aqui o espetinho continua CRU. Depois disso fica no ponto.
@export var perfect_time: float = 10.0
## A partir daqui o espetinho sai TORRADO.
@export var burnt_time: float = 20.0
## A partir daqui o espetinho queima e SOME da churrasqueira.
@export var vanish_time: float = 25.0


@onready var slots_root: Node = get_node_or_null("Bocas")


var _slots: Array[CookingSlot] = []


func _ready() -> void:
	super()
	_collect_slots()
	interactable.target_changed.connect(_on_target_changed)
	set_process(false)


## Enquanto a churrasqueira é o alvo do ESPAÇO, destaca a boca que vai sair
## (muda quando o jogador anda, mexe o mouse ou o espetinho sai).
func _process(_delta: float) -> void:
	_set_target_slot(get_slot_to_collect(interactable.target_actor))


# --- Consultas ---

## Quantas bocas existem.
func get_capacity() -> int:
	return _slots.size()


## Quantas bocas estão ocupadas.
func get_count() -> int:
	var total: int = 0
	for slot in _slots:
		if slot.is_occupied():
			total += 1
	return total


func is_full() -> bool:
	return get_capacity() > 0 and get_count() == get_capacity()


func get_slots() -> Array[CookingSlot]:
	return _slots


## Receita deste item, ou null se a churrasqueira não aceita ele.
func find_recipe(data: ItemData) -> CookingRecipe:
	for entry in recipes:
		var recipe := entry as CookingRecipe
		if recipe and recipe.matches(data):
			return recipe
	return null


## Boca que `actor` esvaziaria se apertasse ESPAÇO agora (mão vazia), ou null.
func get_slot_to_collect(actor: Node) -> CookingSlot:
	if actor == null:
		return null
	var actor_hand: HandComponent = HandComponent.find_in(actor)
	if actor_hand and actor_hand.has_item():
		return null  # com algo na mão, ESPAÇO coloca em vez de tirar
	return _nearest_occupied_slot(actor)


## A churrasqueira aceita este item agora?
func can_accept(data: ItemData) -> bool:
	return not is_full() and find_recipe(data) != null


# --- Interação ---

func _can_interact(actor: Node, actor_hand: HandComponent) -> bool:
	if actor_hand == null:
		return false
	if actor_hand.has_item():
		return can_accept(actor_hand.held_item.data)
	return _nearest_occupied_slot(actor) != null


func _interact(actor: Node, actor_hand: HandComponent) -> void:
	if actor_hand == null:
		return
	if actor_hand.has_item():
		place_item(actor_hand)
	else:
		collect_item(actor, actor_hand)


## Ação secundária (tecla R): joga fora o espetinho da boca mais perto.
func _alt_interact(actor: Node, _actor_hand: HandComponent) -> void:
	var slot: CookingSlot = _nearest_occupied_slot(actor)
	if slot:
		slot.discard()


## Põe o item da mão na primeira boca livre. Retorna true se aceitou.
func place_item(actor_hand: HandComponent) -> bool:
	if actor_hand == null or not actor_hand.has_item():
		return false

	var recipe: CookingRecipe = find_recipe(actor_hand.held_item.data)
	if recipe == null:
		return false

	var slot: CookingSlot = _first_free_slot()
	if slot == null:
		return false

	return slot.place(actor_hand, recipe, recipe.resolve_times(get_default_times()))


## Tira o espetinho da boca mais perto de quem interagiu (mão precisa estar vazia).
func collect_item(actor: Node, actor_hand: HandComponent) -> bool:
	var slot: CookingSlot = _nearest_occupied_slot(actor)
	return slot != null and slot.take(actor_hand)


func get_default_times() -> Vector3:
	var perfect: float = maxf(perfect_time, 0.0)
	var burnt: float = maxf(burnt_time, perfect)
	var vanish: float = maxf(vanish_time, burnt)
	return Vector3(perfect, burnt, vanish)


# --- Interno ---

func _collect_slots() -> void:
	_slots.clear()
	var root: Node = slots_root if slots_root else self
	for child in root.get_children():
		var slot := child as CookingSlot
		if slot == null:
			continue
		_slots.append(slot)
		slot.item_placed.connect(_on_slot_item_placed.bind(slot))
		slot.item_taken.connect(_on_slot_item_taken.bind(slot))
		slot.item_vanished.connect(_on_slot_item_vanished.bind(slot))
	if _slots.is_empty():
		push_warning("CookingStation '%s': nenhum CookingSlot dentro de 'Bocas'." % name)


func _first_free_slot() -> CookingSlot:
	for slot in _slots:
		if slot.is_empty():
			return slot
	return null


## Boca ocupada mais perto do mouse (se ele está em cima da estação) ou de `actor`.
## Empate (ou sem ator): a mais adiantada no fogo.
func _nearest_occupied_slot(actor: Node) -> CookingSlot:
	var origin: Vector2 = Vector2.ZERO
	var has_origin: bool = false
	var node2d := actor as Node2D
	if interactable.is_hovered:
		origin = get_global_mouse_position()
		has_origin = true
	elif node2d:
		origin = node2d.global_position
		has_origin = true

	var best: CookingSlot = null
	var best_distance: float = INF
	for slot in _slots:
		if slot.is_empty():
			continue
		if not has_origin:
			if best == null or slot.get_elapsed() > best.get_elapsed():
				best = slot
			continue
		var distance: float = origin.distance_squared_to(slot.global_position)
		if distance < best_distance - 0.01:
			best_distance = distance
			best = slot
		elif best and absf(distance - best_distance) <= 0.01 and slot.get_elapsed() > best.get_elapsed():
			best = slot
	return best


func _on_target_changed(is_targeted: bool, _actor: Node) -> void:
	set_process(is_targeted)
	if not is_targeted:
		_set_target_slot(null)


func _set_target_slot(target: CookingSlot) -> void:
	for slot in _slots:
		slot.set_targeted(slot == target)
	# Com um espetinho destacado, a silhueta sai da churrasqueira e fica só nele.
	interactable.set_outline_blocked(target != null)


func _on_slot_item_placed(item: CarryableItem, slot: CookingSlot) -> void:
	item_placed.emit(slot, item)


func _on_slot_item_taken(item: CarryableItem, stage: int, slot: CookingSlot) -> void:
	item_collected.emit(slot, item, stage)


func _on_slot_item_vanished(recipe: CookingRecipe, slot: CookingSlot) -> void:
	item_vanished.emit(slot, recipe)
