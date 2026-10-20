extends SummonEntrance
class_name HatchingEgg
## PATOLINO — ENTRADA DO PATO DEVORADOR: um OVO GIGANTE CAI DO CÉU perto do chef e CHOCA.
##
##   1. AVISO: a sombra aparece no chão, piscando (`warning_time` s).
##   2. QUEDA: o ovo despenca girando ("cair") e a sombra cresce (`fall_time` s).
##   3. IMPACTO: quem estiver na sombra (elipse `hit_radius`) leva `damage` e empurrão.
##      Dash (invulnerável) desvia, igual ao raio do Johnny.
##   4. RACHADURAS: o ovo fica balançando ("parado") e racha uma vez a cada
##      `crack_interval` s, tocando as animações de `crack_animations` em ordem
##      (racha_1, racha_2, chocar). CADA RACHADURA É UM QUACK: um patinho aparece gritando
##      em cima do ovo, a tela treme e todo chef a até `quack_radius` px DERRUBA o item
##      (mesmo susto do quack gigante, `QuackAbility.scare`).
##   5. A última animação (chocar) é o pato saindo: o pato devorador aparece no lugar do
##      ovo, com as mecânicas de sempre. A casca ("casca") fica no chão e some.
##
## Números e arte: tudo no inspetor de `ovo_chocando.tscn`.
##
## Estrutura da cena:
##   OvoChocando (Node2D, este script)   a posição é o PONTO DO CHÃO onde o ovo cai
##   ├── Sombra    AnimatedSprite2D "sombra" (quadro 0 = grande, 1 = pequena)
##   ├── Ovo       AnimatedSprite2D cair / parado / racha_1 / racha_2 / chocar / casca
##   └── Impacto   AnimatedSprite2D "impacto" (brilho quando bate no chão; opcional)


signal landed(at: Vector2, hit_bodies: Array)
signal cracked(index: int, items_dropped: int)
signal hatched


@export_group("Queda")
## Segundos com a sombra piscando antes do ovo aparecer caindo.
@export var warning_time: float = 0.6
## De que altura (px acima do chão) o ovo começa a cair.
@export var fall_height: float = 220.0
## Segundos caindo.
@export var fall_time: float = 0.75

## Contorno da área de acerto no chão (aviso). Alfa 0 = sem contorno.
@export var alert_color: Color = Color(1.0, 0.85, 0.3, 0.9)

@export_group("Acerto")
## Raio da área que o ovo acerta ao cair (centro = este nó).
@export var hit_radius: float = 14.0
## Achata o círculo na vertical (chão visto de cima).
@export_range(0.2, 1.0) var vertical_ratio: float = 0.7
@export var target_group: StringName = &"chefs"
## Dano em PONTOS (2 = 1 caveira).
@export var damage: int = 4
@export var knockback: int = 150

@export_group("Rachaduras (quack)")
## Animações tocadas a cada rachadura, em ordem. A ÚLTIMA é o pato saindo (choca).
## Mais ou menos rachaduras = mais ou menos itens na lista.
@export var crack_animations: Array[StringName] = [&"racha_1", &"racha_2", &"chocar"]
## Segundos entre uma rachadura e outra (a 1ª conta a partir do impacto).
@export var crack_interval: float = 1.0
## Balança forte um pouco antes de rachar (aviso), em segundos.
@export var crack_warning_time: float = 0.35
## Distância do ovo até o chef para o quack derrubar o item. 0 = a tela toda.
@export var quack_radius: float = 110.0
## Pulinho do item ao cair (pixels).
@export var drop_hop_height: float = 10.0
## Patinho gritando em cima do ovo a cada rachadura (opcional).
@export var quack_visual: SheetAnimation
## Transparência do patinho gritando (1 = opaco).
@export_range(0.0, 1.0) var quack_opacity: float = 0.9
## Quadro (contando de 1) do patinho em que o bico abre e o chef leva o susto.
@export_range(1, 16) var quack_peak_frame: int = 3
## Tremida da tela em cada quack (pixels). 0 = sem.
@export var quack_shake: float = 2.0
## Som do quack (opcional).
@export var quack_sound: AudioStream

@export_group("Casca")
## Segundos que a casca fica no chão depois que o pato sai.
@export var shell_time: float = 0.8
@export var shell_fade_time: float = 0.5

@export_group("Animações")
@export var fall_animation: StringName = &"cair"
@export var idle_animation: StringName = &"parado"
@export var shell_animation: StringName = &"casca"


var has_landed: bool = false


@onready var shadow: AnimatedSprite2D = get_node_or_null("Sombra")
@onready var egg: AnimatedSprite2D = $Ovo
@onready var impact: AnimatedSprite2D = get_node_or_null("Impacto")

var _egg_base: Vector2 = Vector2.ZERO
var _shadow_base_scale: Vector2 = Vector2.ONE
var _egg_z: int = 0
var _alert_on: bool = false
var _alert_time: float = 0.0


func _ready() -> void:
	_egg_base = egg.position
	_egg_z = egg.z_index
	egg.visible = false
	if shadow:
		_shadow_base_scale = shadow.scale
		shadow.visible = false
	if impact:
		impact.visible = false
	super._ready()


# --- SummonEntrance -------------------------------------------------------------

func _before_summon() -> void:
	await _warn()
	if not is_inside_tree():
		return
	await _fall()
	if not is_inside_tree():
		return
	_land()
	for i in crack_animations.size():
		await _wait(maxf(crack_interval - crack_warning_time, 0.0))
		if not is_inside_tree():
			return
		await _shake_egg(crack_warning_time, 1.5)
		if not is_inside_tree():
			return
		var hatching: bool = i == crack_animations.size() - 1
		await _crack(i, hatching)
		if not is_inside_tree():
			return
	hatched.emit()


func _after_summon() -> void:
	# O pato saiu: sobra a casca no chão.
	if _has(egg, shell_animation):
		egg.play(shell_animation)
	else:
		egg.visible = false
	egg.position = _egg_base
	await _wait(shell_time)
	if not is_inside_tree():
		return
	var tween: Tween = create_tween()
	tween.tween_property(egg, "modulate:a", 0.0, shell_fade_time)
	await tween.finished


# --- Etapas ---------------------------------------------------------------------

func _process(delta: float) -> void:
	if _alert_on:
		_alert_time += delta
		queue_redraw()


## Contorno piscando da área onde o ovo vai cair (fica embaixo do ovo e da sombra).
func _draw() -> void:
	if not _alert_on or alert_color.a <= 0.0:
		return
	var color: Color = alert_color
	color.a *= 0.45 + 0.55 * absf(sin(_alert_time * 9.0))
	var points := PackedVector2Array()
	var steps: int = 20
	for i in steps + 1:
		var angle: float = TAU * i / float(steps)
		points.append(Vector2(cos(angle) * hit_radius, sin(angle) * hit_radius * vertical_ratio).round())
	draw_polyline(points, color, 1.0)


func _set_alert(on: bool) -> void:
	_alert_on = on
	_alert_time = 0.0
	queue_redraw()


## Sombra no chão piscando: "vai cair coisa aqui".
func _warn() -> void:
	_set_alert(true)
	if shadow == null or warning_time <= 0.0:
		await _wait(warning_time)
		return
	shadow.visible = true
	shadow.frame = maxi(shadow.sprite_frames.get_frame_count(shadow.animation) - 1, 0) \
		if shadow.sprite_frames else 0
	shadow.scale = _shadow_base_scale * 0.5
	var tween: Tween = create_tween().set_loops(maxi(int(warning_time / 0.2), 1))
	tween.tween_property(shadow, "modulate:a", 0.25, 0.1)
	tween.tween_property(shadow, "modulate:a", 0.8, 0.1)
	await _wait(warning_time)
	if tween.is_valid():
		tween.kill()
	shadow.modulate.a = 0.8


## O ovo despenca girando; a sombra cresce.
func _fall() -> void:
	egg.visible = true
	egg.z_index = _egg_z + 20  # caindo: na frente de tudo
	egg.position = _egg_base - Vector2(0, fall_height)
	if _has(egg, fall_animation):
		egg.play(fall_animation)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(egg, "position", _egg_base, fall_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if shadow:
		shadow.visible = true
		tween.tween_property(shadow, "scale", _shadow_base_scale, fall_time)
		tween.tween_callback(func() -> void: shadow.frame = 0).set_delay(fall_time * 0.5)
	await tween.finished


## Bateu no chão: dano em quem estava embaixo, brilho, amassadinha.
func _land() -> void:
	has_landed = true
	_set_alert(false)
	egg.z_index = _egg_z
	egg.position = _egg_base
	if _has(egg, idle_animation):
		egg.play(idle_animation)
	if shadow:
		var fade: Tween = create_tween()
		fade.tween_property(shadow, "modulate:a", 0.0, 0.3)
	if impact and _has(impact, &"impacto"):
		impact.visible = true
		impact.play(&"impacto")
		impact.animation_finished.connect(func() -> void: impact.visible = false, CONNECT_ONE_SHOT)

	# Amassa e volta.
	var base_scale: Vector2 = egg.scale
	var squash: Tween = create_tween()
	squash.tween_property(egg, "scale", base_scale * Vector2(1.3, 0.7), 0.06)
	squash.tween_property(egg, "scale", base_scale, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_shake_camera(quack_shake * 1.5, 0.2)

	var hit: Array = GroundStrike.bodies_in_ellipse(get_tree(), target_group, global_position,
			hit_radius, vertical_ratio)
	for body: Node2D in hit:
		if damage > 0 and body.has_method(&"take_damage"):
			var push: Vector2 = body.global_position - global_position
			if push == Vector2.ZERO:
				push = Vector2.DOWN
			body.take_damage(damage, push.normalized(), knockback)
	landed.emit(global_position, hit)


## Uma rachadura = um QUACK. A última choca o pato.
func _crack(index: int, hatching: bool) -> void:
	var animation: StringName = crack_animations[index]
	if _has(egg, animation):
		egg.play(animation)
	_play_sound()

	var dropped: Array = [0]
	var scare := func() -> void:
		dropped[0] = QuackAbility.scare(get_tree(), target_group, global_position,
				quack_radius, drop_hop_height)
		_shake_camera(quack_shake, 0.25)
	var duck: AnimatedSprite2D = _spawn_quack_visual()
	if duck and quack_peak_frame > 1:
		while is_instance_valid(duck) and duck.is_playing() and duck.frame < quack_peak_frame - 1:
			await duck.frame_changed
	if not is_inside_tree():
		return
	scare.call()
	cracked.emit(index, dropped[0])

	if hatching and _has(egg, animation) and not egg.sprite_frames.get_animation_loop(animation):
		await egg.animation_finished


## Patinho gritando em cima do ovo (usa a arte do quack gigante, pequena).
func _spawn_quack_visual() -> AnimatedSprite2D:
	if quack_visual == null or get_parent() == null:
		return null
	var duck: AnimatedSprite2D = SheetAnimation.spawn_once(quack_visual, get_parent(),
			global_position)
	if duck:
		duck.modulate.a = quack_opacity
		# Aparece com um "pop".
		var base: Vector2 = duck.scale
		duck.scale = base * 0.3
		var tween: Tween = duck.create_tween()
		tween.tween_property(duck, "scale", base, 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return duck


# --- Tremidas -------------------------------------------------------------------

## O ovo treme no lugar (aviso de que vai rachar).
func _shake_egg(duration: float, strength: float) -> void:
	if duration <= 0.0:
		return
	var left: float = duration
	while left > 0.0 and is_inside_tree():
		egg.position = _egg_base + Vector2(randf_range(-strength, strength), 0.0)
		await get_tree().create_timer(0.04, false).timeout
		left -= 0.04
	egg.position = _egg_base


## Treme a Camera2D ativa (se a fase tiver uma).
func _shake_camera(strength: float, duration: float) -> void:
	if strength <= 0.0 or not is_inside_tree():
		return
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var base: Vector2 = camera.offset
	var tween: Tween = camera.create_tween()
	var steps: int = maxi(int(duration / 0.04), 1)
	for i in steps:
		var jitter := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
		tween.tween_property(camera, "offset", base + jitter, 0.04)
	tween.tween_property(camera, "offset", base, 0.04)


# --- Utilidades -----------------------------------------------------------------

func _play_sound() -> void:
	if quack_sound == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = quack_sound
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _wait(seconds: float) -> void:
	if seconds > 0.0 and is_inside_tree():
		await get_tree().create_timer(seconds, false).timeout


func _has(sprite: AnimatedSprite2D, animation: StringName) -> bool:
	return sprite != null and sprite.sprite_frames != null and animation != &"" \
		and sprite.sprite_frames.has_animation(animation)
