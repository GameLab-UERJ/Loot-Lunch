extends CharacterBody2D
class_name Summon
## BASE de toda criatura INVOCADA por um cliente (pato devorador do Patolino, demoninho
## da Mandy, ...). Todo cliente tem um summon como ultimate, então o que é comum fica aqui:
##
##   - PERSEGUIR o alvo (chef livre mais perto do grupo `target_group`);
##   - COMEMORAR: se não sobrou alvo livre (todos engolidos/mortos), fica parado tocando
##     `celebrate_animation` ("comemorar"). Enquanto essa animação não existir, usa a de andar.
##     -> quando tiver a arte da dança, é só criar a animação "comemorar" no AnimatedSprite2D;
##   - TEMPO DE VIDA (`lifetime`): acabou -> some com `despawn_animation` ("sumir");
##   - estado OCUPADO (`busy`): o summon está fazendo a coisa dele (engolindo, grudado...)
##     e não anda nem conta o tempo de vida.
##   - DANÇA FORÇADA: qualquer um pode pedir que TODOS os summons dancem
##     (`Summon.request_dance(fonte)` / `Summon.release_dance(fonte)`). Ex.: o demoninho da
##     Mandy grudado no chef faz os outros summons pararem para dançar. Quem tem
##     `obeys_dance_requests` desligado (o próprio demoninho) ignora o pedido.
##
## Quem herda sobrescreve `_pick_target()` (quem perseguir), `_on_reached(alvo)` (encostou)
## e `_get_speed_multiplier()` (buffs).
##
## Estrutura mínima da cena:
##   MeuSummon (CharacterBody2D, script que herda Summon)  layer 0, mask 1 (paredes)
##   ├── AnimatedSprite2D   animações: andar (+ sumir, comemorar... opcionais)
##   └── CollisionShape2D   pequeno, só para não atravessar parede


signal target_reached(target: Node2D)
signal celebrating_changed(celebrating: bool)
signal despawned


const GROUP: StringName = &"summons"


## Quem está pedindo para os summons dançarem (id da instância -> WeakRef).
static var _dance_requests: Dictionary = {}


@export_group("Movimento")
@export var move_speed: float = 45.0
## Grupo de quem é perseguido.
@export var target_group: StringName = &"chefs"
## Distância (centro a centro) que conta como "encostou".
@export var reach_distance: float = 12.0
## A arte olha para a DIREITA? (vira quando anda para a esquerda)
@export var sprite_faces_right: bool = true

@export_group("Vida")
## Segundos até sumir sozinho. 0 = fica até alguém mandar sumir.
@export var lifetime: float = 20.0
## Pisca nos últimos segundos antes de sumir.
@export var warning_time: float = 3.0

@export_group("Animações")
@export var walk_animation: StringName = &"andar"
@export var celebrate_animation: StringName = &"comemorar"
@export var despawn_animation: StringName = &"sumir"
## Animação "pop" ao nascer.
@export var spawn_pop: bool = true

@export_group("Dança")
## Para e dança quando alguém pede (`Summon.request_dance`).
@export var obeys_dance_requests: bool = true


## Quem invocou (o cliente).
var summoner: Node = null
## Quem está sendo perseguido agora.
var target: Node2D = null
var busy: bool = false
var celebrating: bool = false
var despawning: bool = false

var _life_left: float = 0.0


@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	add_to_group(GROUP)
	_life_left = lifetime
	play_animation(walk_animation)
	if spawn_pop and animated_sprite:
		var base: Vector2 = animated_sprite.scale
		animated_sprite.scale = base * 0.2
		var tween: Tween = create_tween()
		tween.tween_property(animated_sprite, "scale", base, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	if despawning:
		return
	if busy:
		velocity = Vector2.ZERO
		return

	_tick_lifetime(delta)
	if despawning:
		return

	if _should_dance():
		target = null
		velocity = Vector2.ZERO
		_set_celebrating(true)
		return

	target = _pick_target()
	_set_celebrating(target == null)
	if target == null:
		velocity = Vector2.ZERO
		return

	var to_target: Vector2 = target.global_position - global_position
	if to_target.length() <= reach_distance:
		velocity = Vector2.ZERO
		target_reached.emit(target)
		_on_reached(target)
		return

	velocity = to_target.normalized() * move_speed * _get_speed_multiplier()
	_face(velocity.x)
	move_and_slide()


## Some (com a animação "sumir", se existir).
func despawn() -> void:
	if despawning:
		return
	despawning = true
	busy = true
	velocity = Vector2.ZERO
	if animated_sprite:
		animated_sprite.modulate.a = 1.0
	if has_animation(despawn_animation):
		play_animation(despawn_animation)
		await animated_sprite.animation_finished
	elif animated_sprite:
		var tween: Tween = create_tween()
		tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.3)
		await tween.finished
	despawned.emit()
	queue_free()


func has_animation(animation: StringName) -> bool:
	return animated_sprite != null and animated_sprite.sprite_frames != null \
		and animation != &"" and animated_sprite.sprite_frames.has_animation(animation)


func play_animation(animation: StringName) -> void:
	if has_animation(animation):
		animated_sprite.play(animation)


## Algum alvo livre? (qualquer um do grupo que não esteja engolido nem morto)
func find_free_target() -> Node2D:
	var best: Node2D = null
	var best_distance: float = INF
	for node in get_tree().get_nodes_in_group(target_group):
		var candidate := node as Node2D
		if candidate == null or not CaptureComponent.is_available_target(candidate):
			continue
		var distance: float = global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


# --- Dança forçada ----------------------------------------------------------------

## `source` pede que os summons dancem (até chamar `release_dance(source)` ou ele sumir).
static func request_dance(source: Object) -> void:
	if source:
		_dance_requests[source.get_instance_id()] = weakref(source)


static func release_dance(source: Object) -> void:
	if source:
		_dance_requests.erase(source.get_instance_id())


## Alguém (ainda vivo) está pedindo dança?
static func is_dance_requested() -> bool:
	for key in _dance_requests.keys():
		var ref: WeakRef = _dance_requests[key]
		var alive: Object = ref.get_ref()
		if alive == null or (alive is Node and not (alive as Node).is_inside_tree()):
			_dance_requests.erase(key)
	return not _dance_requests.is_empty()


# --- Para sobrescrever ---------------------------------------------------------

## Deve parar e dançar agora? (padrão: quando alguém pediu e este summon obedece)
func _should_dance() -> bool:
	return obeys_dance_requests and is_dance_requested()


## Quem perseguir agora. null = ninguém (comemora).
func _pick_target() -> Node2D:
	return find_free_target()


## Encostou no alvo.
func _on_reached(_reached: Node2D) -> void:
	pass


## Buff de velocidade (1 = normal).
func _get_speed_multiplier() -> float:
	return 1.0


# --- Interno -------------------------------------------------------------------

func _tick_lifetime(delta: float) -> void:
	if lifetime <= 0.0:
		return
	_life_left -= delta
	if animated_sprite and warning_time > 0.0 and _life_left <= warning_time:
		animated_sprite.modulate.a = 0.45 if fmod(_life_left, 0.3) < 0.15 else 1.0
	if _life_left <= 0.0:
		despawn()


func _set_celebrating(value: bool) -> void:
	if celebrating == value:
		return
	celebrating = value
	if value:
		if has_animation(celebrate_animation):
			play_animation(celebrate_animation)
		else:
			play_animation(walk_animation)  # sem arte de dança ainda: fica parado "idle"
	else:
		play_animation(walk_animation)
	celebrating_changed.emit(value)


func _face(horizontal: float) -> void:
	if animated_sprite == null or is_zero_approx(horizontal):
		return
	animated_sprite.flip_h = (horizontal < 0.0) == sprite_faces_right
