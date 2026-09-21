extends Character
class_name Chef
## Player cozinheiro. Mesmo modelo do Player (Character + FSM + componentes),
## mas no lugar da espada/inventário tem:
##   - HandComponent (maoUm): carrega 1 item visível na mão
##   - InteractorComponent: detecta bancadas/itens à frente
##   - DashComponent: dash com cooldown e invulnerabilidade


@export_group("Input")
## Nomes das ações do Input Map. Exportados para permitir um 2º jogador com outras teclas.
@export var interact_action: StringName = &"chef_interact"   # B
@export var pick_drop_action: StringName = &"chef_pick_drop" # R
@export var dash_action: StringName = &"chef_dash"           # Space
## Ação secundária das estações: descartar/limpar (raiz de espeto, lixeira...).
@export var trash_action: StringName = &"chef_trash"         # T

@export_group("Itens")
## Distância à frente do chef onde o item cai ao ser largado.
@export var drop_distance: float = 20.0
## Onde os itens largados ficam na árvore. Se vazio, usa o pai do chef (a fase).
@export var items_container: Node

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


func _process(_delta: float) -> void:
	if facing_direction.x > 0 and animated_sprite.flip_h:
		animated_sprite.flip_h = false
	elif facing_direction.x < 0 and not animated_sprite.flip_h:
		animated_sprite.flip_h = true

	hand_component.set_facing(facing_direction)
	interactor_component.set_facing(facing_direction)


func _unhandled_input(event: InputEvent) -> void:
	if not can_act():
		return

	if event.is_action_pressed(dash_action):
		try_dash()
	elif event.is_action_pressed(interact_action):
		interact()
	elif event.is_action_pressed(pick_drop_action):
		pick_or_drop()
	elif event.is_action_pressed(trash_action):
		trash()
	else:
		return
	get_viewport().set_input_as_handled()


# --- Ações (públicas para poderem ser chamadas por IA, testes, tutorial...) ---

## Pode andar/interagir/dar dash? (falso durante dash, hurt, dead ou com controle bloqueado)
func can_act() -> bool:
	return can_control and state_machine.is_free()


func try_dash() -> bool:
	if not can_act():
		return false
	if dash_component.try_dash(facing_direction):
		state_machine.set_state(state_machine.states.dash)
		return true
	return false


## Tecla B: interage com a bancada/caixa/fogão mais próximo à frente.
func interact() -> bool:
	if not can_act():
		return false
	var target: InteractableComponent = interactor_component.get_nearest_interactable()
	if target == null:
		return false
	return target.interact(self)


## Tecla R: com item na mão, larga no chão; com a mão vazia, pega o item do chão mais próximo.
func pick_or_drop() -> bool:
	if not can_act():
		return false
	if hand_component.has_item():
		return drop_item() != null
	var item: CarryableItem = interactor_component.get_nearest_carryable()
	return item != null and hand_component.hold(item)


## Tecla T: ação secundária da estação à frente (limpar a raiz de espeto, lixeira...).
func trash() -> bool:
	if not can_act():
		return false
	var target: InteractableComponent = interactor_component.get_nearest_interactable()
	if target == null:
		return false
	return target.alt_interact(self)


func drop_item() -> CarryableItem:
	var drop_position: Vector2 = global_position + facing_direction * drop_distance
	return hand_component.drop_to(_get_items_container(), drop_position)


func _get_items_container() -> Node:
	return items_container if items_container else get_parent()


# --- Sinais ---

func _on_input_component_direction_changed(new_movement_direction: Vector2) -> void:
	movement_component.move(new_movement_direction)
	if new_movement_direction != Vector2.ZERO:
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
	hurt_sfx.play()


func _on_got_hurt() -> void:
	state_machine.set_state(state_machine.states.hurt)


func _on_died() -> void:
	if hand_component.has_item():
		drop_item()
	interactor_component.update_focus = false
	interactor_component.clear_focus()
	state_machine.set_state(state_machine.states.dead)
