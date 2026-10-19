extends Node2D
class_name TurnAura
## AURA DA VEZ: mostra com clareza que um personagem PODE AGIR agora (vez do jogador
## na batalha por turnos). Sem zoom: só efeito em volta dele.
##
##   - silhueta dourada pulsando em volta do sprite (SpriteOutline);
##   - anel de luz no chão, nos pés, abrindo e sumindo em ondas;
##   - faíscas subindo do chão até a cabeça;
##   - som curto quando a vez COMEÇA (`start_sfx`).
##
## Desenhado por código: não precisa de arte nova. O anel fica ATRÁS do personagem
## (camada `Chao`, z -1) e as faíscas na FRENTE.
## Fica como filho do personagem e anda junto. Não precisa colocar na cena:
##
##   var aura := TurnAura.attach(chef, chef.sprite)
##   aura.set_active(true)   # liga (com som)   /   aura.set_active(false)  # desliga
##
## Reutilizável em qualquer luta por turnos (outro minigame, outro personagem).


const NODE_NAME: StringName = &"TurnAura"


@export var color: Color = Color(1.0, 0.82, 0.25, 1.0)
## Cor clara do miolo das faíscas e do anel.
@export var light_color: Color = Color(1.0, 0.97, 0.75, 1.0)

@export_group("Silhueta")
## Largura da silhueta em pixels da tela.
@export var outline_width: float = 2.0
@export var outline_pulse_speed: float = 5.0

@export_group("Anel no chão")
## Distância do centro do personagem até os pés.
@export var feet_offset: Vector2 = Vector2(0, 20)
## Tamanho do anel (largura, altura) em pixels.
@export var ring_size: Vector2 = Vector2(30, 9)
## Segundos de cada onda do anel.
@export var ring_period: float = 1.1

@export_group("Faíscas")
@export_range(0, 40) var spark_count: int = 10
## Até que altura (acima dos pés) as faíscas sobem.
@export var spark_height: float = 56.0
## Largura da faixa onde as faíscas nascem.
@export var spark_spread: float = 40.0
@export var spark_speed: float = 34.0

@export_group("Som")
## Toca quando a vez começa. Vazio = sem som.
@export var start_sfx: AudioStream = preload("res://assets/sfx/restaurante/chef/skewer_charged.wav")
@export var start_sfx_pitch: float = 0.9
@export var start_sfx_volume_db: float = -2.0

@export_group("Entrada e saída")
@export var fade_in: float = 0.15
@export var fade_out: float = 0.2


## Sprite que ganha a silhueta (normalmente o sprite do personagem).
var sprite: CanvasItem = null
var active: bool = false

var _clock: float = 0.0
var _strength: float = 0.0
var _fade: Tween
var _sparks: Array[Dictionary] = []
var _audio: AudioStreamPlayer = null
var _ground: _GroundLayer = null


## Camada do chão (atrás do personagem): só repassa o desenho para a aura.
class _GroundLayer extends Node2D:
	var aura: TurnAura
	func _draw() -> void:
		aura._draw_ground(self)


## Acha (ou cria) a aura em `owner_node`. `outline_target` = sprite que ganha a silhueta.
static func attach(owner_node: Node2D, outline_target: CanvasItem = null) -> TurnAura:
	if not is_instance_valid(owner_node):
		return null
	var aura := owner_node.get_node_or_null(NodePath(NODE_NAME)) as TurnAura
	if aura == null:
		aura = TurnAura.new()
		aura.name = NODE_NAME
		owner_node.add_child(aura)
	if outline_target:
		aura.sprite = outline_target
	return aura


func _ready() -> void:
	visible = false
	_ground = _GroundLayer.new()
	_ground.name = "Chao"
	_ground.aura = self
	_ground.z_index = -1  # atrás do sprite do personagem, acima do chão da arena
	add_child(_ground)
	_audio = AudioStreamPlayer.new()
	_audio.bus = &"SFX"
	add_child(_audio)


## Liga/desliga. Ligar toca o som (só na passagem de desligada para ligada).
func set_active(value: bool, play_sound: bool = true) -> void:
	if value == active:
		return
	active = value
	if _fade:
		_fade.kill()
	_fade = create_tween()
	if value:
		visible = true
		_reset_sparks()
		_fade.tween_method(_set_strength, _strength, 1.0, fade_in)
		if play_sound and start_sfx and _audio:
			_audio.stream = start_sfx
			_audio.pitch_scale = start_sfx_pitch
			_audio.volume_db = start_sfx_volume_db
			_audio.play()
	else:
		_fade.tween_method(_set_strength, _strength, 0.0, fade_out)
		_fade.tween_callback(func() -> void:
			visible = false
			SpriteOutline.hide_on(sprite))


func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	for spark in _sparks:
		spark[&"y"] -= spark_speed * spark[&"speed"] * delta
		if spark[&"y"] < -spark_height:
			_respawn(spark)
	_refresh_outline()
	queue_redraw()
	_ground.queue_redraw()


func _exit_tree() -> void:
	SpriteOutline.hide_on(sprite)


func _set_strength(value: float) -> void:
	_strength = value
	_refresh_outline()
	queue_redraw()
	if _ground:
		_ground.queue_redraw()


func _refresh_outline() -> void:
	if not is_instance_valid(sprite):
		return
	if _strength <= 0.01:
		SpriteOutline.hide_on(sprite)
		return
	var pulse: float = 0.6 + 0.4 * (0.5 + 0.5 * sin(_clock * outline_pulse_speed))
	var c: Color = color.lerp(light_color, 0.5 * (0.5 + 0.5 * sin(_clock * outline_pulse_speed)))
	c.a = _strength * pulse
	SpriteOutline.show_on(sprite, c, outline_width)


## Camada do chão (atrás do personagem): brilho + anel fixo + duas ondas abrindo.
func _draw_ground(canvas: Node2D) -> void:
	if _strength <= 0.0:
		return
	var feet: Vector2 = feet_offset
	var glow: Color = color
	glow.a = 0.25 * _strength
	canvas.draw_set_transform(feet, 0.0, Vector2(1.0, ring_size.y / ring_size.x))
	canvas.draw_circle(Vector2.ZERO, ring_size.x, glow)
	canvas.draw_set_transform(Vector2.ZERO)
	_draw_ring(canvas, feet, 1.0, 0.7 * _strength, 2.0)
	for k in 2:
		var t: float = fmod(_clock / ring_period + k * 0.5, 1.0)
		_draw_ring(canvas, feet, 1.0 + t * 0.7, (1.0 - t) * 0.85 * _strength, 1.5)


## Frente: faíscas subindo (quadradinhos, combinam com a arte em pixel).
func _draw() -> void:
	if _strength <= 0.0:
		return
	var feet: Vector2 = feet_offset
	for spark in _sparks:
		var life: float = clampf(-spark[&"y"] / spark_height, 0.0, 1.0)
		var alpha: float = sin(PI * life) * _strength
		var pos: Vector2 = feet + Vector2(spark[&"x"] + sin(_clock * 3.0 + spark[&"phase"]) * 2.0, spark[&"y"])
		var size: float = spark[&"size"]
		var outer: Color = color
		outer.a = alpha
		draw_rect(Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size)), outer)
		var inner: Color = light_color
		inner.a = alpha
		draw_rect(Rect2(pos - Vector2(size, size) * 0.25, Vector2(size, size) * 0.5), inner)


func _draw_ring(canvas: Node2D, center: Vector2, grow: float, alpha: float, width: float) -> void:
	if alpha <= 0.0:
		return
	var c: Color = color.lerp(light_color, 0.35)
	c.a = alpha
	var points := PackedVector2Array()
	for i in 33:
		var a: float = TAU * i / 32.0
		points.append(center + Vector2(cos(a) * ring_size.x, sin(a) * ring_size.y) * grow)
	canvas.draw_polyline(points, c, width)


func _reset_sparks() -> void:
	_sparks.clear()
	for i in spark_count:
		var spark: Dictionary = {}
		_respawn(spark)
		spark[&"y"] = -randf() * spark_height  # já começam espalhadas na altura
		_sparks.append(spark)


func _respawn(spark: Dictionary) -> void:
	spark[&"x"] = randf_range(-spark_spread, spark_spread) * 0.5
	spark[&"y"] = 0.0
	spark[&"speed"] = randf_range(0.7, 1.3)
	spark[&"size"] = [2.0, 2.0, 3.0][randi() % 3]
	spark[&"phase"] = randf() * TAU
