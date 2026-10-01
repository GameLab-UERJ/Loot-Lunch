extends Character
class_name Chef
## Player cozinheiro. Mesmo modelo do Player (Character + FSM + componentes),
## mas no lugar da espada/inventário tem:
##   - HandComponent (maoUm): carrega 1 item visível na mão
##   - InteractorComponent: detecta bancadas/itens à frente
##   - DashComponent: dash com cooldown e invulnerabilidade
##   - WalletComponent: carteira (dinheiro dos pedidos)
##   - ManaComponent: barras de mana gastas pelas habilidades
##   - AbilityComponent (filhos): habilidades (Q arremessa espetinho, E deixa sombra)
##   - DeliveryRewardComponent: recupera vida e mana ao entregar pedido
##   - HudChef: caveiras de vida + mana + dinheiro no canto superior esquerdo
##
## VIDA: usa o `hp` do Character (conta em MEIAS caveiras). `max_hp` = 10 -> 5 caveiras.
## Cada ponto de dano tira meia caveira. Quem mostra é o HUD, ouvindo `health_changed`.
##
## STATUS (componentes injetados por quem aplica, o chef só consulta):
##   - ATORDOADO (StunComponent): não anda nem age, mas continua podendo levar dano;
##   - CONFUSO (ConfusionComponent): as setas ficam invertidas;
##   - LENTO (SlowComponent): mexe sozinho no max_speed.
##
## HABILIDADES: o chef só REPASSA as teclas para os filhos AbilityComponent
## (press ao apertar, release ao soltar, interrupt ao levar dano). Nova habilidade =
## novo nó filho; nada muda aqui.


## Vida mudou (dano, cura, reviver). O HUD escuta este sinal.
signal health_changed(current: int, maximum: int)


## Grupo de todos os chefs. Clientes (magias) e summons procuram o alvo por aqui.
const GROUP: StringName = &"chefs"


@export_group("Input")
## Nomes das ações do Input Map. Exportados para permitir um 2º jogador com outras teclas.
@export var interact_action: StringName = &"chef_interact"   # F (ou clique direito)
@export var pick_drop_action: StringName = &"chef_pick_drop" # Espaço
@export var dash_action: StringName = &"chef_dash"           # Shift
## Ação secundária das estações: descartar/limpar (raiz de espeto, lixeira...).
@export var trash_action: StringName = &"chef_trash"         # R

@export_group("Itens")
## Distância à frente do chef onde o item cai ao ser largado.
@export var drop_distance: float = 20.0
## Onde os itens largados ficam na árvore. Se vazio, usa o pai do chef (a fase).
@export var items_container: Node

@export_group("Vida")
## Vida máxima em pontos (2 pontos = 1 caveira). 6 = 3 caveiras, 10 = 5 caveiras.
@export var max_hp: int = 10

@export_group("Sprite")
## Para qual lado a ARTE do chef olha, sem espelhar. A arte jscoutinho olha para a
## DIREITA, então fica desligado. Se trocar por uma arte virada para a esquerda
## (o personagem começar a andar "de costas"), é só ligar aqui.
@export var sprite_faces_left: bool = false

@export_group("Dash")
@export var dash_sprite_alpha: float = 0.55


var can_control: bool = true
var facing_direction: Vector2 = Vector2.RIGHT


@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var hand_component: HandComponent = %HandComponent
@onready var interactor_component: InteractorComponent = %InteractorComponent
@onready var dash_component: DashComponent = %DashComponent
@onready var state_machine: ChefFSM = %FiniteStateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var footsteps_sfx: AudioStreamPlayer2D = $FootstepsSfx
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSfx
@onready var dash_sfx: AudioStreamPlayer2D = $DashSfx
@onready var wallet: WalletComponent = get_node_or_null("WalletComponent")
@onready var mana: ManaComponent = ManaComponent.find_in(self)
@onready var abilities: Array[AbilityComponent] = AbilityComponent.find_all_in(self)


func _ready() -> void:
	add_to_group(GROUP)
	hp = clampi(hp, 0, max_hp)
	health_changed.emit(hp, max_hp)


func _process(_delta: float) -> void:
	if not is_zero_approx(facing_direction.x):
		var looking_left: bool = facing_direction.x < 0
		animated_sprite.flip_h = looking_left != sprite_faces_left

	hand_component.set_facing(facing_direction)
	interactor_component.set_facing(facing_direction)


func _unhandled_input(event: InputEvent) -> void:
	# Habilidades primeiro: SOLTAR a tecla precisa chegar mesmo com o chef ocupado.
	if _handle_ability_input(event):
		get_viewport().set_input_as_handled()
		return

	if not can_act():
		return

	if event.is_action_pressed(dash_action):
		try_dash()
	elif event.is_action_pressed(interact_action):
		interact(event is InputEventMouseButton)
	elif event.is_action_pressed(pick_drop_action):
		pick_or_drop()
	elif event.is_action_pressed(trash_action):
		trash(event is InputEventMouseButton)
	else:
		return
	get_viewport().set_input_as_handled()


# --- Ações (públicas para poderem ser chamadas por IA, testes, tutorial...) ---

## Pode interagir/pegar/dar dash/usar habilidade?
## (falso durante dash, hurt, dead, atordoado, com controle bloqueado ou carregando uma habilidade)
func can_act() -> bool:
	return can_control and state_machine.is_free() and not is_using_ability() \
		and not is_stunned()


## Atordoado (choque do Johnny...)? Parado e sem agir, mas pode levar dano.
func is_stunned() -> bool:
	return StunComponent.is_active_on(self)


# --- Habilidades ---

## Alguma habilidade está em andamento (ex.: segurando Q para arremessar)?
func is_using_ability() -> bool:
	for ability in abilities:
		if ability.is_busy():
			return true
	return false


## Alguma habilidade está controlando para onde o chef olha (ex.: mira do mouse)?
func is_facing_locked() -> bool:
	for ability in abilities:
		if ability.controls_facing():
			return true
	return false


## Aperta a habilidade ligada à ação (ex.: &"chef_ability_throw"). Público para IA/testes.
func use_ability(action: StringName) -> bool:
	for ability in abilities:
		if ability.action == action:
			return can_act() and ability.press()
	return false


## Solta a tecla da habilidade (arremessa se estiver carregado).
func release_ability(action: StringName) -> void:
	for ability in abilities:
		if ability.action == action:
			ability.release()


## Cancela tudo que estiver carregando (levou dano, morreu...).
func interrupt_abilities() -> void:
	for ability in abilities:
		ability.interrupt()


func _handle_ability_input(event: InputEvent) -> bool:
	for ability in abilities:
		if ability.action == &"" or not InputMap.has_action(ability.action):
			continue
		if event.is_action_released(ability.action):
			ability.release()
			return true
		if event.is_action_pressed(ability.action):
			if can_act():
				ability.press()
			return true
	return false


func try_dash() -> bool:
	if not can_act():
		return false
	if dash_component.try_dash(facing_direction):
		state_machine.set_state(state_machine.states.dash)
		return true
	return false


## Tecla F (ou clique direito): interage com o objeto embaixo do mouse (se estiver
## ao alcance) ou com a bancada/caixa/fogão mais próximo à frente.
## `from_mouse` = veio do clique: aí clicar num objeto LONGE não faz nada. Pelo
## teclado, mouse parado em cima de algo longe não atrapalha: vale o que está à frente.
func interact(from_mouse: bool = false) -> bool:
	if not can_act():
		return false
	var target: InteractableComponent = interactor_component.get_target(not from_mouse)
	if target == null:
		return false
	return target.interact(self)


## Espaço: com item na mão, larga no chão; com a mão vazia, pega o item do chão mais próximo.
func pick_or_drop() -> bool:
	if not can_act():
		return false
	if hand_component.has_item():
		return drop_item() != null
	var item: CarryableItem = interactor_component.get_nearest_carryable()
	return item != null and hand_component.hold(item)


## Tecla R: ação secundária da estação à frente (limpar a raiz de espeto, lixeira...).
func trash(from_mouse: bool = false) -> bool:
	if not can_act():
		return false
	var target: InteractableComponent = interactor_component.get_target(not from_mouse)
	if target == null:
		return false
	return target.alt_interact(self)


# --- Vida ---

func is_dead() -> bool:
	return hp <= 0


## Recupera vida (em pontos: 1 = meia caveira). Se estava morto, revive.
func heal(amount: int) -> void:
	if amount <= 0 or hp >= max_hp:
		return
	var was_dead: bool = is_dead()
	hp = mini(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)
	if was_dead:
		_revive()


func heal_full() -> void:
	heal(max_hp - hp)


func _revive() -> void:
	visible = true  # pode ter sido escondido (ex.: arrastado para o inferno pela Mandy)
	animated_sprite.visible = true
	interactor_component.update_focus = true
	state_machine.set_state(state_machine.states.idle)


func drop_item() -> CarryableItem:
	var drop_position: Vector2 = global_position + facing_direction * drop_distance
	return hand_component.drop_to(_get_items_container(), drop_position)


func _get_items_container() -> Node:
	return items_container if items_container else get_parent()


# --- Sinais ---

func _on_input_component_direction_changed(new_movement_direction: Vector2) -> void:
	# Confuso: as setas invertem (esquerda vira direita, cima vira baixo).
	new_movement_direction = ConfusionComponent.transform_direction(self, new_movement_direction)
	movement_component.move(new_movement_direction)
	# Mirando com o mouse (segurando Q), quem decide para onde o chef olha é a mira.
	if new_movement_direction != Vector2.ZERO and not is_facing_locked():
		facing_direction = new_movement_direction.normalized()


func _on_frame_changed() -> void:
	if not animated_sprite.animation == "move" or state_machine.state == state_machine.states.dash:
		return

	match animated_sprite.frame:
		1, 4:
			footsteps_sfx.play()


func _on_dash_component_dash_started(_direction: Vector2) -> void:
	animated_sprite.modulate.a = dash_sprite_alpha
	dash_sfx.play()


func _on_dash_component_dash_finished() -> void:
	animated_sprite.modulate.a = 1.0


func _on_took_damage() -> void:
	interrupt_abilities()  # levou golpe segurando Q -> o espetinho cai no chão
	hp = maxi(hp, 0)
	health_changed.emit(hp, max_hp)
	hurt_sfx.play()


func _on_got_hurt() -> void:
	state_machine.set_state(state_machine.states.hurt)


func _on_died() -> void:
	interrupt_abilities()
	if hand_component.has_item():
		drop_item()
	interactor_component.update_focus = false
	interactor_component.clear_focus()
	state_machine.set_state(state_machine.states.dead)
