extends Summon
class_name DevourerDuck
## PATOLINO — MAGIA 3 (ULTIMATE): PATO DEVORADOR (summon).
##
## 1. Nasce na frente do Patolino e PERSEGUE o chef livre mais perto.
## 2. Encostou -> animação "devorar" (bote e engolida). O chef some dentro do pato:
##    larga o item, perde o controle, fica invulnerável e grudado na barriga.
## 3. Pato CHEIO ("cheio", em loop). Aparece a barra + setinhas ◀ ▶: o jogador tem que
##    apertar ◀ e ▶ ALTERNADAS para encher a barra. Parou de apertar, a barra esvazia.
##    Encheu -> o chef é cuspido (com invencibilidade) e o pato some ("sumir").
## 4. Se houver OUTRO pato devorador no cenário, ele ganha BUFF DE VELOCIDADE
##    (`hunt_speed_multiplier`) e corre para comer o pato cheio. Chegou -> "devorar" o pato
##    cheio e depois "finalizar" (super cheio e sumiço): o chef é FINALIZADO, não importa
##    a vida que tinha.
## 5. Outros summons sem nada para fazer ficam parados comemorando (ver Summon).
##
## Desviar: o pato não morde quem está invulnerável/invencível (dash, piscando após dano).
##
## A barriga é um CaptureComponent (reutilizável); a perseguição vem do Summon.


signal devoured(chef: Node2D)
signal chef_escaped(chef: Node2D)
signal chef_finalized(chef: Node2D)


@export_group("Devorar")
@export var devour_animation: StringName = &"devorar"
@export var full_animation: StringName = &"cheio"
@export var finish_animation: StringName = &"finalizar"
## Quadro (contando de 1) de "devorar" em que a presa some dentro do bico.
@export_range(1, 16) var swallow_frame: int = 5
## Quadro (contando de 1) de "finalizar" em que o chef é finalizado (a nuvem aparece).
@export_range(1, 16) var finish_frame: int = 4

@export_group("Caçar pato cheio")
## Buff de velocidade quando está indo comer um pato cheio (1 = sem buff).
@export var hunt_speed_multiplier: float = 1.8
## Acelera as perninhas também enquanto caça.
@export var hunt_animation_speed: float = 1.8


## Tem um chef na barriga?
var is_full: bool = false
## Outro pato já está comendo este.
var being_eaten: bool = false


@onready var belly: CaptureComponent = $Barriga


func _ready() -> void:
	super._ready()
	belly.escaped.connect(_on_chef_escaped)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if animated_sprite and not busy:
		var hunting: bool = target is DevourerDuck
		animated_sprite.speed_scale = hunt_animation_speed if hunting else 1.0


# --- Summon ---------------------------------------------------------------------

## Prioridade: um pato cheio para comer (finaliza o chef). Senão, um chef livre.
func _pick_target() -> Node2D:
	var full_duck: DevourerDuck = _find_full_duck()
	if full_duck:
		return full_duck
	return find_free_target()


func _get_speed_multiplier() -> float:
	return hunt_speed_multiplier if target is DevourerDuck else 1.0


func _on_reached(reached: Node2D) -> void:
	if reached is DevourerDuck:
		_eat_full_duck(reached)
	elif _can_bite(reached):
		_devour_chef(reached)


# --- Devorar o chef ---------------------------------------------------------------

func _can_bite(chef: Node2D) -> bool:
	if not CaptureComponent.is_available_target(chef):
		return false
	# Desviou: dash (invulnerável) ou piscando depois de levar dano / escapar (invencível).
	return chef.get(&"is_invulnerable") != true and chef.get(&"is_invincible") != true


func _devour_chef(chef: Node2D) -> void:
	busy = true
	animated_sprite.speed_scale = 1.0
	_face(chef.global_position.x - global_position.x)
	if not belly.capture(chef, false):
		busy = false
		return

	await _play_until_frame(devour_animation, swallow_frame)
	if not is_inside_tree():
		return
	belly.hide_target()
	await _wait_animation_end(devour_animation)
	if not is_inside_tree() or not belly.has_target():
		return

	is_full = true
	play_animation(full_animation)
	belly.escape_active = true
	devoured.emit(chef)


func _on_chef_escaped(chef: Node2D) -> void:
	is_full = false
	chef_escaped.emit(chef)
	despawn()  # cuspiu o chef e some


# --- Comer o pato cheio (finaliza o chef) ------------------------------------------

func _find_full_duck() -> DevourerDuck:
	var best: DevourerDuck = null
	var best_distance: float = INF
	for node in get_tree().get_nodes_in_group(GROUP):
		var duck := node as DevourerDuck
		if duck == null or duck == self or not duck.is_full or duck.being_eaten or duck.despawning:
			continue
		var distance: float = global_position.distance_squared_to(duck.global_position)
		if distance < best_distance:
			best_distance = distance
			best = duck
	return best


func _eat_full_duck(other: DevourerDuck) -> void:
	busy = true
	animated_sprite.speed_scale = 1.0
	other.being_eaten = true
	_face(other.global_position.x - global_position.x)

	await _play_until_frame(devour_animation, swallow_frame)
	if not is_inside_tree():
		return

	# O chef pode ter escapado no último segundo.
	if not is_instance_valid(other) or not other.belly.has_target() or other.despawning:
		if is_instance_valid(other):
			other.being_eaten = false
		busy = false
		play_animation(walk_animation)
		return

	other.belly.transfer_to(belly)
	other.is_full = false
	other.queue_free()  # engolido inteiro, sem nuvem
	await _wait_animation_end(devour_animation)
	if not is_inside_tree():
		return

	# Super cheio... e some. O chef é finalizado quando a nuvem aparece.
	despawning = true
	var victim: Node2D = belly.target
	await _play_until_frame(finish_animation, finish_frame)
	if not is_inside_tree():
		return
	belly.finalize()
	chef_finalized.emit(victim)
	await _wait_animation_end(finish_animation)
	despawned.emit()
	queue_free()


# --- Animação -------------------------------------------------------------------

## Toca `animation` e espera chegar no quadro `frame_1based` (ou acabar).
func _play_until_frame(animation: StringName, frame_1based: int) -> void:
	if not has_animation(animation):
		return
	animated_sprite.speed_scale = 1.0
	animated_sprite.play(animation)
	frame_1based = clampi(frame_1based, 1, animated_sprite.sprite_frames.get_frame_count(animation))
	while is_inside_tree() and animated_sprite.animation == animation \
			and animated_sprite.is_playing() and animated_sprite.frame < frame_1based - 1:
		await animated_sprite.frame_changed


func _wait_animation_end(animation: StringName) -> void:
	if not has_animation(animation):
		return
	if animated_sprite.animation == animation and animated_sprite.is_playing():
		await animated_sprite.animation_finished
