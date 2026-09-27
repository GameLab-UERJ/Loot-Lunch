extends Summon
class_name LittleDemon
## MANDY — MAGIA 3 (ULTIMATE): DEMONINHO (summon).
##
## 1. Nasce na frente da Mandy ("invocar") e VOA atrás do chef livre mais perto ("voo").
## 2. Encostou -> "grudar" -> fica GRUDADO no chef ("grudado", em loop), andando junto.
##    O chef continua andando, mas com `attached_slow` (90%) de lentidão.
##    Enquanto ele está grudado, os OUTROS summons (pato do Patolino...) param e DANÇAM.
## 3. Depois de `attached_time` segundos (pisca no final) ele solta, cai e derrete
##    ("morrer") e o chef volta ao normal.
## 4. Se houver OUTRO demoninho no mapa, este fica mais rápido (`hunt_speed_multiplier`)
##    e vai no chef que já tem um demoninho grudado. Chegou -> os dois se FUNDEM ("fusao")
##    num demônio grandão que AGARRA o chef ("agarrado"), dá RISADA ("risada"), abre um
##    BURACO DO INFERNO embaixo dele e ARRASTA o chef para dentro ("arrastar"). O chef é
##    FINALIZADO, não importa a vida que tinha.
##
## Desviar: ele não gruda em quem está invulnerável/invencível (dash, piscando após dano).
## O agarrão final usa o CaptureComponent (sem fuga); a lentidão, o SlowComponent; o
## buraco, o SinkHole. A perseguição e a dança vêm do Summon.


signal attached(chef: Node2D)
signal detached(chef: Node2D)
signal fused(chef: Node2D)
signal chef_finalized(chef: Node2D)


enum State { SPAWNING, FLYING, GRABBING, ATTACHED, DYING, FUSING }


@export_group("Grudar")
## Segundos GRUDADO no chef até cair e derreter sozinho. Mude aqui para testar.
@export var attached_time: float = 8.0
## Lentidão enquanto está grudado (0.9 = anda só 10% da velocidade).
@export_range(0.0, 1.0) var attached_slow: float = 0.9
@export var slow_tint: Color = Color(1.0, 0.72, 0.72)
## Posição em relação ao centro do chef (a arte já foi desenhada centrada nele).
@export var attach_offset: Vector2 = Vector2.ZERO
## Pisca nos últimos segundos grudado.
@export var attached_warning_time: float = 2.0
## Os outros summons dançam enquanto este está grudado.
@export var make_others_dance: bool = true

@export_group("Caçar (2º demoninho)")
## Buff de velocidade quando existe outro demoninho no mapa (1 = sem buff).
@export var hunt_speed_multiplier: float = 1.8
## Acelera as asinhas também.
@export var hunt_animation_speed: float = 1.6

@export_group("Arrastar para o inferno")
## Cena do buraco (SinkHole).
@export var hole_scene: PackedScene = preload("res://restaurante/clientes/mandy/habilidades/buraco_inferno.tscn")
## Segundos segurando o chef antes de rir.
@export var grab_time: float = 0.8
## Quantas vezes toca a risada.
@export_range(0, 8) var laugh_loops: int = 2
## Onde o buraco abre, em relação ao centro do chef (o meio do buraco fica no pé dele).
@export var hole_offset: Vector2 = Vector2(0, -2)
## Depois de finalizar, esconde o chef (foi levado para o inferno). Ele volta a
## aparecer quando reviver (Chef._revive).
@export var hide_victim_body: bool = true

@export_group("Animações")
@export var spawn_animation: StringName = &"invocar"
@export var grab_animation: StringName = &"grudar"
@export var attached_animation: StringName = &"grudado"
@export var fusion_animation: StringName = &"fusao"
@export var hold_animation: StringName = &"agarrado"
@export var laugh_animation: StringName = &"risada"
@export var drag_animation: StringName = &"arrastar"


var state: State = State.SPAWNING
## O chef em que está grudado (ou agarrando, na fusão).
var victim: Node2D = null

var _attached_left: float = 0.0


@onready var grab: CaptureComponent = $Agarrar


func _ready() -> void:
	super._ready()
	if has_animation(spawn_animation):
		busy = true
		play_animation(spawn_animation)
		await animated_sprite.animation_finished
		if not is_inside_tree() or state != State.SPAWNING:
			return
		busy = false
		play_animation(walk_animation)
	state = State.FLYING


func _exit_tree() -> void:
	_clear_effects()


func _physics_process(delta: float) -> void:
	match state:
		State.ATTACHED:
			_process_attached(delta)
			return
		State.GRABBING:
			_follow_victim()
			return
		State.FUSING, State.DYING, State.SPAWNING:
			return
	super._physics_process(delta)
	if animated_sprite and not busy and not despawning and not celebrating:
		animated_sprite.speed_scale = hunt_animation_speed if _is_hunting() else 1.0


## Está grudado num chef agora?
func is_attached() -> bool:
	return state == State.ATTACHED or state == State.GRABBING


# --- Summon ---------------------------------------------------------------------

## Prioridade: o chef que já tem OUTRO demoninho grudado (para fundir). Senão, chef livre.
func _pick_target() -> Node2D:
	var partner: LittleDemon = _find_attached_partner()
	if partner and CaptureComponent.is_available_target(partner.victim):
		return partner.victim
	return find_free_target()


func _get_speed_multiplier() -> float:
	return hunt_speed_multiplier if _is_hunting() else 1.0


func _should_dance() -> bool:
	return false  # demoninho não para para dançar: ele é quem faz os outros dançarem


func _on_reached(reached: Node2D) -> void:
	if not _can_grab(reached):
		return
	var partner: LittleDemon = _find_attached_partner(reached)
	if partner:
		_fuse_with(partner, reached)
	else:
		_attach_to(reached)


# --- Grudar ------------------------------------------------------------------------

func _can_grab(chef: Node2D) -> bool:
	if not CaptureComponent.is_available_target(chef):
		return false
	return chef.get(&"is_invulnerable") != true and chef.get(&"is_invincible") != true


func _attach_to(chef: Node2D) -> void:
	state = State.GRABBING
	busy = true
	victim = chef
	z_index = 1
	animated_sprite.speed_scale = 1.0
	_face(chef.global_position.x - global_position.x)
	SlowComponent.apply(chef, self, attached_slow, 0.0, slow_tint)
	if make_others_dance:
		Summon.request_dance(self)

	if has_animation(grab_animation):
		play_animation(grab_animation)
		await animated_sprite.animation_finished
		if not is_inside_tree() or state != State.GRABBING:
			return

	state = State.ATTACHED
	_attached_left = attached_time
	play_animation(attached_animation)
	attached.emit(chef)


func _process_attached(delta: float) -> void:
	if not CaptureComponent.is_available_target(victim):
		_die()  # o chef morreu ou foi engolido por outra coisa: cai fora
		return
	_follow_victim()

	_attached_left -= delta
	if animated_sprite and attached_warning_time > 0.0 and _attached_left <= attached_warning_time:
		animated_sprite.modulate.a = 0.45 if fmod(_attached_left, 0.3) < 0.15 else 1.0
	if _attached_left <= 0.0:
		_die()


func _follow_victim() -> void:
	if is_instance_valid(victim):
		global_position = victim.global_position + attach_offset


## Solta o chef, cai e derrete ("morrer").
func _die() -> void:
	if state == State.DYING:
		return
	var old_victim: Node2D = victim
	state = State.DYING
	_clear_effects()
	victim = null
	if animated_sprite:
		animated_sprite.speed_scale = 1.0
	if is_instance_valid(old_victim):
		detached.emit(old_victim)
	despawn()


# --- Fusão + buraco do inferno -----------------------------------------------------

func _fuse_with(partner: LittleDemon, chef: Node2D) -> void:
	state = State.FUSING
	busy = true
	victim = chef
	z_index = 1
	animated_sprite.speed_scale = 1.0
	animated_sprite.modulate.a = 1.0
	if make_others_dance:
		Summon.request_dance(self)

	# O parceiro some dentro da fusão (a arte da fusão já desenha os dois).
	partner.absorb()
	global_position = chef.global_position + attach_offset
	animated_sprite.flip_h = false
	if not grab.capture(chef, false):
		state = State.FLYING
		busy = false
		Summon.release_dance(self)
		return
	fused.emit(chef)

	await _play_once(fusion_animation)
	if not _still_holding():
		return
	play_animation(hold_animation)
	await get_tree().create_timer(grab_time, false).timeout
	if not _still_holding():
		return
	for i in laugh_loops:
		await _play_once(laugh_animation)
		if not _still_holding():
			return

	# Abre o buraco embaixo do chef (atrás dele e do demônio).
	var hole: SinkHole = _open_hole(chef)
	if hole:
		await hole.open()
		if not _still_holding():
			hole.close()
			return
	play_animation(drag_animation)

	if hole:
		hole.add_ghost(chef.get_node_or_null("AnimatedSprite2D") as CanvasItem)
		hole.add_ghost(animated_sprite)
		grab.hide_target()
		await hole.sink()
		if not is_inside_tree():
			return

	var body: Node2D = grab.target
	grab.finalize()
	if hide_victim_body and is_instance_valid(body):
		body.visible = false  # foi para o inferno: nem a animação de morte aparece
	chef_finalized.emit(body)

	if hole:
		await hole.close()
	despawned.emit()
	queue_free()


## Este demoninho foi engolido pela fusão com outro.
func absorb() -> void:
	state = State.FUSING
	busy = true
	_clear_effects()
	victim = null
	visible = false
	queue_free()


func _open_hole(chef: Node2D) -> SinkHole:
	if hole_scene == null:
		return null
	var hole := hole_scene.instantiate() as SinkHole
	if hole == null:
		return null
	var world: Node = chef.get_parent() if chef.get_parent() else get_parent()
	world.add_child(hole)
	hole.global_position = chef.global_position + hole_offset
	if chef.get_parent() == world:
		world.move_child(hole, chef.get_index())  # desenhado antes = atrás do chef
	return hole


func _still_holding() -> bool:
	return is_inside_tree() and grab.has_target()


func _play_once(animation: StringName) -> void:
	if not has_animation(animation):
		return
	animated_sprite.speed_scale = 1.0
	animated_sprite.play(animation)
	animated_sprite.frame = 0
	await animated_sprite.animation_finished


# --- Outros demoninhos --------------------------------------------------------------

## Outro demoninho vivo no mapa? (buff de velocidade)
func _is_hunting() -> bool:
	for node in get_tree().get_nodes_in_group(GROUP):
		var other := node as LittleDemon
		if other and other != self and other.state != State.DYING and not other.despawning \
				and other.state != State.FUSING:
			return true
	return false


## Outro demoninho grudado (em `chef`, se passado).
func _find_attached_partner(chef: Node2D = null) -> LittleDemon:
	for node in get_tree().get_nodes_in_group(GROUP):
		var other := node as LittleDemon
		if other == null or other == self or not other.is_attached():
			continue
		if chef == null or other.victim == chef:
			return other
	return null


## Tira a lentidão e o pedido de dança deste demoninho.
func _clear_effects() -> void:
	if is_instance_valid(victim):
		SlowComponent.remove(victim, self)
	Summon.release_dance(self)
	if animated_sprite:
		animated_sprite.modulate.a = 1.0
