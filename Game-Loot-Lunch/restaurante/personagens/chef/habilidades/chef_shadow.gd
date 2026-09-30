extends Node2D
class_name ChefShadow
## A SOMBRA que o chef deixa no chão (habilidade da tecla E).
##
## Aparece com um "pop", fica parada respirando (animação idle da sombra), pisca nos
## últimos `warning_time` segundos e some quando o tempo acaba. Quem usa (ShadowAbility)
## define o tempo com `start_lifetime(segundos)`.
##
## Fica no grupo `group_name`, então qualquer sistema futuro (inimigo que se distrai,
## 2º chef...) acha as sombras com get_tree().get_nodes_in_group(&"sombras_chef").
##
## Cena: sombra.tscn (AnimatedSprite2D com os 4 quadros de jscoutinho_idle_L_34F_sombra.png).


## A sombra começou a sumir (tempo acabou, foi usada ou substituída).
signal expired


## Tempo de vida padrão, usado só se ninguém chamar start_lifetime. 0 = não some sozinha.
@export var lifetime: float = 10.0
@export var fade_in_time: float = 0.2
@export var fade_out_time: float = 0.6
## Nos últimos segundos, pisca avisando que vai sumir. 0 = não pisca.
@export var warning_time: float = 2.0
@export var warning_blink_speed: float = 14.0
## Grupo em que a sombra se registra.
@export var group_name: StringName = &"sombras_chef"
## Opacidade da sombra parada.
@export_range(0.0, 1.0) var opacity: float = 0.85


## Quem deixou a sombra (o Chef).
var source: Node = null

var _time_left: float = -1.0
var _expiring: bool = false
var _lifetime_started: bool = false
var _intro_tween: Tween


@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	add_to_group(group_name)
	if sprite:
		sprite.play(&"idle")

	# Aparece com um "pop" (estica e volta) e fade in.
	modulate.a = 0.0
	scale = Vector2(1.25, 0.75)
	_intro_tween = create_tween().set_parallel(true)
	_intro_tween.tween_property(self, "modulate:a", opacity, fade_in_time)
	_intro_tween.tween_property(self, "scale", Vector2.ONE, fade_in_time * 1.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if not _lifetime_started and lifetime > 0.0:
		start_lifetime(lifetime)


## Começa (ou recomeça) a contagem até sumir. 0 ou menos = não some sozinha.
func start_lifetime(seconds: float) -> void:
	_lifetime_started = true
	_time_left = seconds if seconds > 0.0 else -1.0


func get_time_left() -> float:
	return maxf(_time_left, 0.0)


func is_expiring() -> bool:
	return _expiring


func _process(delta: float) -> void:
	if _expiring or _time_left < 0.0:
		return
	_time_left -= delta
	if sprite and warning_time > 0.0 and _time_left <= warning_time:
		sprite.visible = sin(_time_left * warning_blink_speed) > -0.3
	if _time_left <= 0.0:
		expire()


## Deixa a sombra olhando para o mesmo lado que o chef estava.
func set_flip_h(value: bool) -> void:
	if sprite:
		sprite.flip_h = value


## O tempo acabou: some devagar.
func expire() -> void:
	_leave(fade_out_time, Vector2.ONE)


## Foi usada (o chef voltou para ela): some rápido, "encolhendo".
func vanish() -> void:
	_leave(0.15, Vector2(0.4, 1.4))


func _leave(time: float, end_scale: Vector2) -> void:
	if _expiring or not is_inside_tree():
		return
	_expiring = true
	if _intro_tween:
		_intro_tween.kill()
	modulate.a = opacity
	scale = Vector2.ONE
	if sprite:
		sprite.visible = true
	remove_from_group(group_name)
	expired.emit()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, time)
	tween.tween_property(self, "scale", end_scale, time)
	tween.chain().tween_callback(queue_free)
