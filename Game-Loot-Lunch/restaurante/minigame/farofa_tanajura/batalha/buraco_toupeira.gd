extends Node2D
class_name BuracoToupeira
## Um BURACO do ataque "Cavar" (estilo jogo da toupeira). O jogador CLICA no buraco
## de onde acha que a formiga vai sair. O buraco só avisa `chosen`; quem decide se
## acertou é a habilidade Cavar.
##
## Cena: buraco_toupeira.tscn (Sprite2D buraco_terra.png com 3 quadros + ClickTargetComponent).
##   quadro 0 = buraco | 1 = tremendo (terra saltando) | 2 = antenas aparecendo


signal chosen(hole: BuracoToupeira)


var index: int = 0
var _tremble_left: float = 0.0
var _tremble_strength: float = 0.0
var _clock: float = 0.0
## Quadro fixo (ex.: depois que a formiga saiu). -1 = livre.
var _locked_frame: int = -1


@onready var sprite: Sprite2D = $Sprite2D
@onready var click: ClickTargetComponent = $ClickTargetComponent


func _ready() -> void:
	click.clicked.connect(func() -> void: chosen.emit(self))
	click.enabled = false


## Aparece com um "pop" de terra.
func appear() -> void:
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_clickable(value: bool) -> void:
	click.enabled = value


## Treme por `duration` s. `strength` 1 = a formiga está mesmo aqui; menos = disfarce.
func tremble(strength: float, duration: float) -> void:
	_tremble_strength = strength
	_tremble_left = duration


func _process(delta: float) -> void:
	_clock += delta
	if _tremble_left > 0.0:
		_tremble_left -= delta
		sprite.frame = 2 if _tremble_strength >= 1.0 and fmod(_clock, 0.5) < 0.2 else 1
		sprite.position = Vector2(sin(_clock * 60.0) * 1.5 * _tremble_strength, 0.0)
	else:
		sprite.position = Vector2.ZERO
		sprite.frame = _locked_frame if _locked_frame >= 0 else 0


## Clicou no buraco errado: pisca vermelho.
func show_empty() -> void:
	sprite.modulate = Color(1.0, 0.4, 0.4)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.4)


## A formiga saiu daqui: o buraco "explode" de terra.
func burst() -> void:
	_tremble_left = 0.0
	_locked_frame = 2
	var tween := create_tween()
	tween.tween_property(sprite, "scale", sprite.scale * Vector2(1.3, 1.3), 0.08)
	tween.tween_property(sprite, "scale", sprite.scale, 0.1)


func vanish() -> void:
	click.enabled = false
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.2)
	tween.tween_callback(queue_free)
