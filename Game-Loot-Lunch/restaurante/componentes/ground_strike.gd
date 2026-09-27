extends Node2D
class_name GroundStrike
## ATAQUE QUE CAI DO CÉU NUM PONTO MARCADO (raio do Johnny, raio supremo, e futuramente
## meteoro, bigorna...). Só a arte e os números mudam; a sequência é sempre a mesma:
##
##   alerta no chão: "intro" (1x) -> "loop" (`warning_time` s) -> "final" (1x, pisca)
##   queda: toca "queda"; no quadro `impact_frame` ACERTA quem estiver no círculo
##   marca: a marca queimada fica no chão `mark_time` s e some devagar
##
## Acertou (não estava invulnerável/dando dash): `damage`, empurrão e ATORDOADO
## (`stun_duration` s com a arte `stun_visual`). Tudo 0 = só visual.
## Avisa `struck` no impacto: a magia pode soltar mais coisas dali (esferas, nuvem...).
##
## Estrutura da cena:
##   Raio (Node2D, este script)          a posição é o CENTRO DO ALERTA NO CHÃO
##   ├── Alerta   AnimatedSprite2D       animações intro / loop / final (no chão, z 0:
##   │                                   quem cria coloca o nó antes do chef na árvore)
##   ├── Marca    CanvasItem opcional    marca queimada (aparece depois)
##   └── Queda    AnimatedSprite2D       animação queda (o raio). Ajuste o `offset` para
##                                       o pé do raio ficar no centro do alerta.


signal struck(at: Vector2, hit_bodies: Array)
signal finished


@export_group("Tempo")
## Segundos do alerta piscando antes do raio cair (sem contar intro/final).
@export var warning_time: float = 1.0
## Quadro da "queda" em que o raio toca o chão (0 = primeiro).
@export var impact_frame: int = 2
## Segundos que a marca queimada fica no chão.
@export var mark_time: float = 3.0
@export var mark_fade_time: float = 0.8

@export_group("Acerto")
## Raio do círculo que acerta (centro = posição deste nó).
@export var hit_radius: float = 18.0
## Achata o círculo na vertical (chão visto de cima). 1 = círculo, 0.6 = elipse.
@export_range(0.2, 1.0) var vertical_ratio: float = 0.7
@export var target_group: StringName = &"chefs"
## Dano em PONTOS (2 = 1 caveira). 0 = sem dano.
@export var damage: int = 0
@export var knockback: int = 0
## Segundos ATORDOADO. 0 = não atordoa.
@export var stun_duration: float = 2.0
## Arte que fica em cima de quem foi atordoado.
@export var stun_visual: SheetAnimation

@export_group("Animações")
@export var alert_intro: StringName = &"intro"
@export var alert_loop: StringName = &"loop"
@export var alert_final: StringName = &"final"
@export var fall_animation: StringName = &"queda"


var has_struck: bool = false


@onready var alert: AnimatedSprite2D = get_node_or_null("Alerta")
@onready var fall: AnimatedSprite2D = get_node_or_null("Queda")
@onready var mark: CanvasItem = get_node_or_null("Marca")


func _ready() -> void:
	if fall:
		fall.visible = false
	if mark:
		mark.visible = false
	_run()


func _run() -> void:
	# 1. alerta
	if alert:
		alert.visible = true
		await _play(alert, alert_intro)
		if _has(alert, alert_loop):
			alert.play(alert_loop)
		if warning_time > 0.0:
			await get_tree().create_timer(warning_time, false).timeout
		await _play(alert, alert_final)
		alert.visible = false
	elif warning_time > 0.0:
		await get_tree().create_timer(warning_time, false).timeout

	# 2. queda
	if fall and _has(fall, fall_animation):
		fall.visible = true
		fall.frame_changed.connect(_on_fall_frame_changed)
		fall.play(fall_animation)
		if impact_frame <= 0:
			_strike()
		await fall.animation_finished
		fall.visible = false
	_strike()  # garante o acerto mesmo sem arte

	# 3. marca queimada
	if mark:
		mark.visible = true
		if mark is AnimatedSprite2D:
			(mark as AnimatedSprite2D).play()
		await get_tree().create_timer(maxf(mark_time, 0.0), false).timeout
		var tween: Tween = create_tween()
		tween.tween_property(mark, "modulate:a", 0.0, mark_fade_time)
		await tween.finished
	finished.emit()
	queue_free()


## Quem está dentro do círculo agora (sem contar quem está invulnerável).
func get_bodies_in_area() -> Array:
	var found: Array = []
	for node in get_tree().get_nodes_in_group(target_group):
		var body := node as Node2D
		if body == null or not CaptureComponent.is_available_target(body):
			continue
		if body.get(&"is_invulnerable") == true:
			continue  # dash: desviou
		var delta: Vector2 = body.global_position - global_position
		delta.y /= maxf(vertical_ratio, 0.01)
		if delta.length() <= hit_radius:
			found.append(body)
	return found


func _on_fall_frame_changed() -> void:
	if fall.frame >= impact_frame:
		_strike()


func _strike() -> void:
	if has_struck:
		return
	has_struck = true
	var hit: Array = get_bodies_in_area()
	for body: Node2D in hit:
		if damage > 0 and body.has_method(&"take_damage"):
			var push: Vector2 = (body.global_position - global_position).normalized()
			body.take_damage(damage, push, knockback)
		if stun_duration > 0.0:
			# A fonte é a ARTE: dois raios seguidos renovam o stun, não empilham.
			StunComponent.apply(body, stun_visual if stun_visual else &"ground_strike",
					stun_duration, stun_visual)
	struck.emit(global_position, hit)


func _play(sprite: AnimatedSprite2D, animation: StringName) -> void:
	if not _has(sprite, animation):
		return
	sprite.play(animation)
	await sprite.animation_finished


func _has(sprite: AnimatedSprite2D, animation: StringName) -> bool:
	return sprite != null and sprite.sprite_frames != null and animation != &"" \
		and sprite.sprite_frames.has_animation(animation)
