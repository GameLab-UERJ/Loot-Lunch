extends Node2D
class_name Battler
## BASE de quem luta na batalha da Fase 3 (ChefBattler, FormigaBattler...).
##
## Cuida só do que é comum: vida (BattleHealthComponent filho), tempo de espera
## (BattleWaitComponent filho), sprite (SheetSprite filho "Sprite") e os MOVIMENTOS de
## cena que toda habilidade usa:
##   await battler.move_to(pos, 0.3)        # corre até a posição
##   await battler.return_home()            # volta para o lugar dele
##   await battler.hop(24, 0.3)             # pulinho
##   await battler.act(&"frigideirada", 4)  # toca a animação de ação e espera o quadro do golpe
##   await battler.sink_into_ground(40)     # afunda no chão (cortado pela linha do chão)
##   battler.take_hit(3, direção)           # dano + piscar + empurrão + número subindo
##
## As habilidades (BattleSkill / FormigaSkill) só chamam isso: nenhuma precisa saber
## como cada lutador é desenhado.


signal hit_taken(amount: int)


@export var display_name: String = "Lutador"
## Cor do número de dano que sobe.
@export var damage_color: Color = Color(1.0, 0.45, 0.35)
## Onde ficam os pés em relação à origem (px). Usado para efeitos no chão e para afundar.
@export var ground_offset: float = 20.0
## Animações básicas.
@export var idle_animation: StringName = &"idle"
@export var walk_animation: StringName = &"andar"


## Lugar "de descanso" na arena (definido por quem posiciona).
var home_position: Vector2 = Vector2.ZERO
var _flash_tween: Tween
var _clip: Polygon2D


@onready var health: BattleHealthComponent = BattleHealthComponent.find_in(self)
@onready var wait: BattleWaitComponent = BattleWaitComponent.find_in(self)
@onready var sprite: SheetSprite = get_node_or_null("Sprite")


func _ready() -> void:
	home_position = global_position


func is_dead() -> bool:
	return health == null or health.is_dead()


## No ar (voando): golpes corpo a corpo não alcançam. A base nunca voa.
func is_airborne() -> bool:
	return false


## Chamado pelas habilidades À DISTÂNCIA (Besta) depois de acertar. A base não faz nada;
## a Rainha usa para cair do céu e devolver a mana do chef.
func on_ranged_hit(_battle: Node, _user: Battler) -> void:
	pass


## Posição dos pés (global).
func feet_position() -> Vector2:
	return global_position + Vector2(0.0, ground_offset)


## Leva o golpe. Retorna o dano que de fato entrou.
func take_hit(amount: int, from_direction: Vector2 = Vector2.ZERO) -> int:
	var dealt: int = health.damage(amount) if health else 0
	if dealt <= 0:
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -40), "Defendeu!", Color(0.8, 0.9, 1.0))
		return 0
	hit_taken.emit(dealt)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -40), "-%d" % dealt, damage_color)
	flash()
	if from_direction != Vector2.ZERO and sprite:
		var push: Vector2 = from_direction.normalized() * 8.0
		var tween := create_tween()
		tween.tween_property(sprite, "position", push, 0.06)
		tween.tween_property(sprite, "position", Vector2.ZERO, 0.14)
	return dealt


## Cura com número verde subindo.
func heal(amount: int) -> int:
	var gained: int = health.heal(amount) if health else 0
	if gained > 0:
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -44), "+%d" % gained, Color(0.55, 1.0, 0.55))
	return gained


func flash(color: Color = Color(3.0, 3.0, 3.0)) -> void:
	if sprite == null:
		return
	if _flash_tween:
		_flash_tween.kill()
	sprite.modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func move_to(target: Vector2, duration: float, trans: Tween.TransitionType = Tween.TRANS_QUAD) -> void:
	if sprite:
		sprite.play_sheet(walk_animation)
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, duration).set_trans(trans).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if sprite and sprite.animation == walk_animation:
		sprite.play_sheet(idle_animation)


func return_home(duration: float = 0.3) -> void:
	await move_to(home_position, duration)


## Toca uma animação de AÇÃO (frigideirada, besta, contra-ataque...) e espera o quadro
## do golpe (`hit_frame`, 0 = primeiro; -1 = não espera). A animação termina sozinha
## e volta para o idle. Sem essa animação na sprite, não faz nada (a habilidade segue).
func act(anim_name: StringName, hit_frame: int = -1) -> bool:
	if sprite == null or not sprite.play_sheet(anim_name, true):
		return false
	_back_to_idle_after(anim_name)
	if hit_frame >= 0:
		await sprite.wait_frame(anim_name, hit_frame)
	return true


## Espera a animação de ação atual acabar (se ainda estiver tocando).
func finish_action() -> void:
	if sprite == null:
		return
	if sprite.animation != idle_animation and sprite.animation != walk_animation and sprite.is_playing() \
			and not sprite.sprite_frames.get_animation_loop(sprite.animation):
		await sprite.animation_finished


func _back_to_idle_after(anim_name: StringName) -> void:
	await sprite.animation_finished
	if is_instance_valid(sprite) and sprite.animation == anim_name:
		sprite.play_sheet(idle_animation)


## Pulinho no lugar (o corpo sobe e desce; a "sombra" fica).
func hop(height: float = 24.0, duration: float = 0.35) -> void:
	if sprite == null:
		return
	var base: Vector2 = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(sprite, "position", base + Vector2(0, -height), duration * 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position", base, duration * 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished


## "Amassa" o sprite (preparando bote, pisada...). Volta ao normal sozinho.
func squash(amount: Vector2 = Vector2(1.25, 0.75), duration: float = 0.25) -> void:
	if sprite == null:
		return
	var base_scale: Vector2 = sprite.scale
	var tween := create_tween()
	tween.tween_property(sprite, "scale", base_scale * amount, duration * 0.6)
	tween.tween_property(sprite, "scale", base_scale, duration * 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


## Vira o sprite para olhar para `point`. `faces_left` = a arte original olha para a esquerda.
func face(point: Vector2, faces_left: bool = false) -> void:
	if sprite == null or is_equal_approx(point.x, global_position.x):
		return
	var looking_left: bool = point.x < global_position.x
	sprite.flip_h = looking_left != faces_left
	sprite.refresh_offset()


## AFUNDA no chão: o desenho desce `depth` px e some cortado pela linha dos pés
## (máscara com `clip_children`, sem shader). Fica escondido até `rise_from_ground`.
func sink_into_ground(depth: float, duration: float) -> void:
	if sprite == null:
		return
	_begin_clip()
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", depth, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished


## SOBE do chão (o contrário de `sink_into_ground`). Chame depois de reposicionar.
func rise_from_ground(depth: float, duration: float) -> void:
	if sprite == null:
		return
	_begin_clip()
	sprite.position.y = depth
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", 0.0, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	_end_clip()


func _begin_clip() -> void:
	if _clip:
		return
	# Tudo ACIMA da linha dos pés aparece; o que desce passa da linha e é cortado.
	_clip = Polygon2D.new()
	_clip.name = "CorteChao"
	_clip.polygon = PackedVector2Array([Vector2(-200, -400), Vector2(200, -400),
		Vector2(200, ground_offset), Vector2(-200, ground_offset)])
	_clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	add_child(_clip)
	move_child(_clip, sprite.get_index())
	sprite.reparent(_clip, false)


func _end_clip() -> void:
	if _clip == null:
		return
	sprite.reparent(self, false)
	move_child(sprite, _clip.get_index())
	_clip.queue_free()
	_clip = null
