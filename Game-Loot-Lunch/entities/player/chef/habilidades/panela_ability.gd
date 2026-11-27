extends AbilityComponent
class_name PanelaAbility
## HABILIDADE: PANELA (combate igual ao do jogo normal com a espada).
##
##   F (`action`)            -> SACA a panela. Se estiver segurando um item, o item CAI
##                              no chão e a panela aparece na mão. F de novo GUARDA.
##   Clique (`attack_action`) -> com a panela sacada, bate na direção do MOUSE
##                              (o mesmo `ui_attack` do Player com a espada).
##   Pegou um item            -> a panela é GUARDADA sozinha (a mão fica com o item).
##
## Sacada, a panela aponta para o mouse e o chef olha para a mira (como o Player).
## Não gasta mana (`mana_cost` = 0 no chef.tscn). Durante o golpe o chef não interage
## nem dá dash; depois tem um `cooldown` curto.
##
## Colocar como filho do Chef e apontar `weapon` para o nó Panela (panela.tscn).


@export var weapon: Panela
## Ação que BATE (com a panela sacada). Mesma do Player: botão do mouse.
@export var attack_action: StringName = &"ui_attack"
## Mira com o mouse. Desligado = bate para onde o chef está olhando (WASD).
@export var aim_with_mouse: bool = true
## Mouse mais perto que isso do chef = usa a direção em que ele olha.
@export var mouse_dead_zone: float = 6.0
## Tempo depois do golpe até poder bater de novo.
@export var cooldown: float = 0.1


var _busy_left: float = 0.0
var _cooldown_left: float = 0.0


func _ready() -> void:
	super()
	if weapon == null:
		weapon = user.get_node_or_null("Panela") as Panela
	if weapon == null:
		push_warning("PanelaAbility: nenhuma Panela no chef.")
		return
	var hand := user.get_node_or_null("HandComponent") as HandComponent
	if hand:
		hand.item_held.connect(_on_item_held)
	if user.has_signal(&"died"):
		user.died.connect(holster)


func _process(delta: float) -> void:
	if _busy_left > 0.0:
		_busy_left = maxf(_busy_left - delta, 0.0)
	elif _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if is_drawn():
		var aim: Vector2 = get_aim_direction()
		weapon.aim(aim)
		if controls_facing():
			user.set(&"facing_direction", aim)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or not is_drawn():
		return
	if attack_action == &"" or not InputMap.has_action(attack_action):
		return
	if event.is_action_pressed(attack_action):
		attack()
		get_viewport().set_input_as_handled()


# --- Público (IA, testes, tutorial) --------------------------------------------

func is_drawn() -> bool:
	return weapon != null and weapon.is_drawn()


## Saca a panela. Segurando um item, o item cai no chão antes.
func draw() -> bool:
	if weapon == null or not enabled:
		return false
	if is_drawn():
		return true
	var hand := user.get_node_or_null("HandComponent") as HandComponent
	if hand and hand.has_item():
		if not user.has_method("drop_item") or user.drop_item() == null:
			return false
	weapon.draw_weapon()
	activated.emit()
	return true


func holster() -> void:
	_busy_left = 0.0
	if weapon:
		weapon.holster()


## Bate (precisa estar sacada). Retorna true se o golpe saiu.
func attack() -> bool:
	if not is_drawn() or is_busy() or _cooldown_left > 0.0:
		return false
	if user.has_method("can_act") and not user.can_act():
		return false
	weapon.aim(get_aim_direction())
	_busy_left = weapon.swing()
	_cooldown_left = cooldown
	return true


## Direção da mira: mouse (se ligado) ou para onde o chef olha.
func get_aim_direction() -> Vector2:
	if aim_with_mouse and user is Node2D:
		var to_mouse: Vector2 = (user as Node2D).get_global_mouse_position() - (user as Node2D).global_position
		if to_mouse.length() > mouse_dead_zone:
			return to_mouse.normalized()
	var facing = user.get(&"facing_direction")
	return facing if facing is Vector2 and facing != Vector2.ZERO else Vector2.RIGHT


# --- AbilityComponent ----------------------------------------------------------

func is_busy() -> bool:
	return _busy_left > 0.0


## Sacada com mira do mouse: o chef olha para a mira (andar não vira ele).
func controls_facing() -> bool:
	return is_drawn() and aim_with_mouse


## F: saca (largando o item da mão) ou guarda.
func _on_press() -> bool:
	if is_drawn():
		holster()
		return true
	return draw()


func _on_interrupt() -> void:
	_busy_left = 0.0
	if weapon:
		weapon.cancel()


func _on_item_held(_item: CarryableItem) -> void:
	holster()
