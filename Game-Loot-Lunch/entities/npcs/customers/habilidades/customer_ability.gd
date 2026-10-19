extends AbilityComponent
class_name CustomerAbility
## BASE de toda MAGIA DE CLIENTE (quack do Patolino, ovo, pato devorador, magias da Mandy
## e do Johnny...). Herda o AbilityComponent do chef, então o "apertar" é o mesmo `press()`;
## a diferença é que quem aperta é o jogo (paciência do cliente), não uma tecla.
##
## Cuida do que é comum a todas as magias de cliente:
##   - achar o ALVO: o chef mais perto do grupo `target_group` que esteja livre
##     (não engolido, não morto) e dentro de `max_range`;
##   - "preparar" a magia (`windup_time`): o cliente dá uma encolhidinha antes, para o
##     jogador perceber que vem coisa;
##   - `cooldown` entre um uso e outro.
##
## Quem herda só escreve `_perform(alvo)` com o efeito da magia.
##
## Coloque como filho de um CustomerAbilityCaster (nó "Habilidades" do cliente). O
## `caster` (quem lança) é o CLIENTE, não o nó "Habilidades".


signal cast_started(target: Node2D)
signal cast_finished(target: Node2D)


## Grupo do nó que marca o MEIO DO MAPA (opcional: coloque um Marker2D na fase com este grupo).
const MAP_CENTER_GROUP: StringName = &"centro_mapa"


@export_group("Alvo")
## Grupo de quem pode ser alvo. Os chefs entram em "chefs" sozinhos (chef.gd).
@export var target_group: StringName = &"chefs"
## Distância máxima até o alvo. 0 = qualquer distância.
@export var max_range: float = 0.0
## Sem alvo disponível a magia não sai.
@export var requires_target: bool = true
## Sem alvo (chef engolido pelo pato, morto...), a magia sai MESMO ASSIM, no MEIO DO MAPA.
## Ligado nas ultimates. O meio do mapa é um nó do grupo "centro_mapa" (ex.: um Marker2D
## na fase); sem ele, o centro da câmera; sem câmera, o centro da tela.
@export var fallback_to_map_center: bool = false

@export_group("Tempo")
## Segundos "preparando" antes do efeito (o cliente encolhe e estica).
@export var windup_time: float = 0.3
## Espera mínima entre dois usos. 0 = pode usar de novo logo.
@export var cooldown: float = 0.0


## O cliente que lança a magia.
var caster: Node2D = null

var _busy: bool = false
var _cooldown_left: float = 0.0


func _init() -> void:
	mana_cost = 0  # cliente não tem mana


func _ready() -> void:
	caster = _find_caster()
	user = caster
	mana = null


func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)


## Lança a magia. `target` vazio = procura o chef mais perto.
func cast(target: Node2D = null) -> bool:
	if not enabled or _busy or _cooldown_left > 0.0 or not is_inside_tree():
		return false
	if target == null or not CaptureComponent.is_available_target(target):
		target = find_target()
	if target == null and requires_target and not fallback_to_map_center:
		return false
	_run(target)
	return true


func is_busy() -> bool:
	return _busy


func is_ready() -> bool:
	return enabled and not _busy and _cooldown_left <= 0.0


## O chef livre mais perto do cliente (ou null).
func find_target() -> Node2D:
	var origin: Vector2 = caster.global_position if caster else Vector2.ZERO
	var best: Node2D = null
	var best_distance: float = INF
	for node in get_tree().get_nodes_in_group(target_group):
		var candidate := node as Node2D
		if candidate == null or not CaptureComponent.is_available_target(candidate):
			continue
		var distance: float = origin.distance_to(candidate.global_position)
		if max_range > 0.0 and distance > max_range:
			continue
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


## Para onde mirar: o alvo, se existir; senão o MEIO DO MAPA.
func get_aim_position(target: Node2D) -> Vector2:
	if is_instance_valid(target):
		return target.global_position
	return CustomerAbility.map_center_of(self)


## Meio do mapa, visto de `node`: nó do grupo "centro_mapa" > centro da câmera > centro da tela.
static func map_center_of(node: Node) -> Vector2:
	if node == null or not node.is_inside_tree():
		return Vector2.ZERO
	var marker := node.get_tree().get_first_node_in_group(MAP_CENTER_GROUP) as Node2D
	if marker:
		return marker.global_position
	var viewport: Viewport = node.get_viewport()
	var camera: Camera2D = viewport.get_camera_2d()
	if camera:
		return camera.get_screen_center_position()
	var screen_center: Vector2 = viewport.get_visible_rect().size * 0.5
	return viewport.get_canvas_transform().affine_inverse() * screen_center


## Onde colocar coisas criadas pela magia (projéteis, summons): a fase do cliente.
func get_world() -> Node:
	if caster and caster.get_parent():
		return caster.get_parent()
	return get_tree().current_scene


# --- AbilityComponent ----------------------------------------------------------

func _on_press() -> bool:
	return cast()


func _on_interrupt() -> void:
	_busy = false


# --- Para sobrescrever ---------------------------------------------------------

## O efeito da magia. Pode usar `await` (ex.: esperar uma animação).
func _perform(_target: Node2D) -> void:
	pass


# --- Interno -------------------------------------------------------------------

func _run(target: Node2D) -> void:
	_busy = true
	activated.emit()
	cast_started.emit(target)

	if windup_time > 0.0:
		_play_windup()
		await get_tree().create_timer(windup_time, false).timeout
		if not is_inside_tree() or not _busy:
			return

	if target != null and not CaptureComponent.is_available_target(target):
		target = find_target()  # o alvo sumiu/foi engolido durante a preparação
	await _perform(target)

	if not is_inside_tree():
		return
	_busy = false
	_cooldown_left = cooldown
	cast_finished.emit(target)


## Encolhe e estica o sprite do cliente (aviso visual de que vem magia).
func _play_windup() -> void:
	var sprite := caster.get_node_or_null("AnimatedSprite2D") as Node2D if caster else null
	if sprite == null:
		return
	var base: Vector2 = sprite.scale
	var tween: Tween = sprite.create_tween()
	tween.tween_property(sprite, "scale", base * Vector2(1.2, 0.8), windup_time * 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", base * Vector2(0.9, 1.15), windup_time * 0.25)
	tween.tween_property(sprite, "scale", base, windup_time * 0.15)


func _find_caster() -> Node2D:
	var node: Node = get_parent()
	while node != null and (node is CustomerAbilityCaster or not node is Node2D):
		node = node.get_parent()
	return node as Node2D
