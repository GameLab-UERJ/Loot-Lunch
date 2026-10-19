extends Node2D
class_name MiniSol
## MINI-SOL: a esfera de fogo conjurada pelo chef acima da carne (Fase 1).
##
## Enquanto está CANALIZANDO (`set_channeling(true)`), brilha forte e solta fagulhas
## em arco na direção de `target` (a carne). Quanto maior a `intensity` (0..1, a etapa
## passa o ponto da carne), mais rápido saem as fagulhas.
##
## Não sabe o que é queimar: só cria a fagulha e avisa `spark_spawned(fagulha)`.
## Quem cuida das consequências é a CarneSolMinigame.


signal spark_spawned(spark: FagulhaSolar)


@export var spark_scene: PackedScene
## Onde as fagulhas caem (a carne). Sem alvo = embaixo do sol.
@export var target: Node2D
## Para onde as fagulhas vão na árvore. Vazio = pai do sol.
@export var sparks_container: Node

@export_group("Fagulhas")
@export var spawn_enabled: bool = true
## Intervalo entre fagulhas com intensidade 0 e 1 (segundos).
@export var interval_calm: float = 1.7
@export var interval_furious: float = 0.6
## Tempo de voo sorteado (mais alto = mais tempo para clicar).
@export var flight_time_min: float = 1.4
@export var flight_time_max: float = 2.1
## Quanto a fagulha pode cair longe do centro do alvo.
@export var land_spread: Vector2 = Vector2(22, 6)

@export_group("Visual")
@export var glow_color: Color = Color(1.0, 0.7, 0.25, 0.25)
@export var glow_radius: float = 26.0


var intensity: float = 0.0
var channeling: bool = false
var _cooldown: float = 0.8
var _clock: float = 0.0


@onready var sprite: Node2D = get_node_or_null("Sprite")


func set_channeling(value: bool) -> void:
	channeling = value


func _process(delta: float) -> void:
	_clock += delta
	var power: float = (0.55 + 0.45 * intensity) if channeling else 0.25
	if sprite:
		var pulse: float = 1.0 + 0.06 * sin(_clock * (6.0 + 10.0 * intensity))
		sprite.scale = Vector2.ONE * lerpf(1.4, 2.0, power) * pulse
		sprite.modulate.a = lerpf(0.55, 1.0, power)
	queue_redraw()

	if not channeling or not spawn_enabled or spark_scene == null:
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown = lerpf(interval_calm, interval_furious, clampf(intensity, 0.0, 1.0)) \
			* randf_range(0.8, 1.2)
		spawn_spark()


func spawn_spark() -> FagulhaSolar:
	var spark := spark_scene.instantiate() as FagulhaSolar
	if spark == null:
		push_warning("MiniSol: spark_scene precisa ter o script FagulhaSolar na raiz.")
		return null
	var container: Node = sparks_container if sparks_container else get_parent()
	container.add_child(spark)
	var to: Vector2 = target.global_position if target else global_position + Vector2(0, 120)
	to += Vector2(randf_range(-land_spread.x, land_spread.x), randf_range(-land_spread.y, land_spread.y))
	# Salta para um dos lados do sol antes de cair (arco bonito, nunca reto).
	var from: Vector2 = global_position + Vector2(randf_range(-14.0, 14.0), -6.0)
	spark.launch(from, to, randf_range(flight_time_min, flight_time_max))
	spark_spawned.emit(spark)
	return spark


func _draw() -> void:
	var power: float = (0.55 + 0.45 * intensity) if channeling else 0.25
	for i in 3:
		var r: float = glow_radius * (1.0 + i * 0.35) * (0.7 + 0.6 * power)
		draw_circle(Vector2.ZERO, r, Color(glow_color, glow_color.a * power / (i + 1)))
