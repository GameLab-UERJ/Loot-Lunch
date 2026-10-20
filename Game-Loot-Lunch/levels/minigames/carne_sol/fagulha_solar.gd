extends Node2D
class_name FagulhaSolar
## FAGULHA que salta do Mini-Sol e cai em ARCO na carne. O jogador precisa CLICAR
## nela antes que encoste (ClickTargetComponent filho). Encostou = queimadura na carne.
##
## Quem cria (MiniSol) chama `launch(de, para, tempo_de_voo)`. A fagulha não sabe nada
## de carne: só avisa `landed` (caiu) ou `caught` (foi pega).
##
## Cena: fagulha_solar.tscn (SheetSprite + ClickTargetComponent).


signal landed(spark: FagulhaSolar)
signal caught(spark: FagulhaSolar)


@export var gravity: float = 150.0
## Fica maior e mais vermelha no fim do voo (aviso de que vai encostar).
@export var warning_time: float = 0.45


var velocity: Vector2 = Vector2.ZERO
var _flight_time: float = 1.0
var _time: float = 0.0
var _done: bool = false
var _base_scale: Vector2 = Vector2.ONE


@onready var sprite: Node2D = $Sprite
@onready var click: ClickTargetComponent = $ClickTargetComponent


func _ready() -> void:
	_base_scale = sprite.scale
	click.clicked.connect(_on_clicked)


## Calcula a velocidade inicial para cair EXATAMENTE em `to` depois de `flight_time` s.
func launch(from: Vector2, to: Vector2, flight_time: float) -> void:
	global_position = from
	_flight_time = maxf(flight_time, 0.2)
	velocity = (to - from - 0.5 * Vector2(0.0, gravity) * _flight_time * _flight_time) / _flight_time


func _process(delta: float) -> void:
	if _done:
		return
	_time += delta
	velocity.y += gravity * delta
	global_position += velocity * delta
	var left: float = _flight_time - _time
	if left <= warning_time:
		var t: float = 1.0 - clampf(left / warning_time, 0.0, 1.0)
		sprite.scale = _base_scale * (1.0 + 0.4 * t)
		sprite.modulate = Color(1.0, 1.0 - 0.5 * t, 1.0 - 0.6 * t)
	if _time >= _flight_time:
		_land()


func _land() -> void:
	_done = true
	click.enabled = false
	landed.emit(self)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 0.4), 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)


func _on_clicked() -> void:
	if _done:
		return
	_done = true
	click.enabled = false
	caught.emit(self)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.2, 2.2), 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(1.6, 1.6, 1.0, 0.0), 0.18)
	tween.chain().tween_callback(queue_free)
