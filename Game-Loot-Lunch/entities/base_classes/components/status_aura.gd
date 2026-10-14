extends Node2D
class_name StatusAura
## AURA DE STATUS que GRUDA num personagem e anda junto com ele: símbolo de bruxaria da
## Mandy (lentidão), futuramente o "desorientado" do Johnny, veneno, congelado...
##
## Ciclo:  surgir (1x) -> loop (enquanto durar) -> fim (1x) -> some
## Enquanto está ativa aplica a LENTIDÃO (`slow_percent`) com o SlowComponent. Não tem
## colisão: pegou, pegou (não dá para fugir nem com dash, porque ela vai junto).
##
## Estrutura da cena:
##   Aura (Node2D, este script)
##   ├── Chao    AnimatedSprite2D, fica ATRÁS do personagem (animações surgir / loop / fim)
##   └── Frente  AnimatedSprite2D opcional, fica NA FRENTE (partículas; animação loop)
##
## Uso:  StatusAura.attach(cena, alvo, duracao)   ou   aura.start(alvo, duracao)


signal started(target: Node2D)
signal finished(target: Node2D)


@export_group("Efeito")
## Segundos no loop (sem contar surgir e fim). 0 = até alguém chamar `finish()`.
@export var duration: float = 4.0
## 0.2 = o personagem anda 20% mais devagar.
@export_range(0.0, 1.0) var slow_percent: float = 0.2
## Cor do personagem enquanto está lento.
@export var slow_tint: Color = Color(0.85, 0.7, 1.0)
## A lentidão já começa no "surgir" (true) ou só no loop (false).
@export var slow_from_start: bool = true

@export_group("Posição")
## Onde a aura fica em relação ao centro do personagem.
@export var offset: Vector2 = Vector2.ZERO
## Desenha a parte "Chao" atrás do personagem.
@export var ground_behind_target: bool = true

@export_group("Animações")
@export var start_animation: StringName = &"surgir"
@export var loop_animation: StringName = &"loop"
@export var end_animation: StringName = &"fim"


var target: Node2D = null
var active: bool = false
var ending: bool = false

var _time_left: float = 0.0
var _finished_emitted: bool = false


@onready var ground: AnimatedSprite2D = get_node_or_null("Chao")
@onready var front: AnimatedSprite2D = get_node_or_null("Frente")


## Cria a aura da cena `scene` e gruda em `on_target`. `time` < 0 = usa o `duration` da cena.
static func attach(scene: PackedScene, on_target: Node2D, time: float = -1.0) -> StatusAura:
	if scene == null or on_target == null or not is_instance_valid(on_target):
		return null
	var aura := scene.instantiate() as StatusAura
	if aura == null:
		push_error("StatusAura.attach: a cena não tem o script StatusAura na raiz.")
		return null
	aura.start(on_target, time)
	return aura


## Gruda em `on_target` e começa. `time` < 0 = usa `duration`.
func start(on_target: Node2D, time: float = -1.0) -> void:
	target = on_target
	if time >= 0.0:
		duration = time
	# Filho do personagem: anda junto sem precisar de código.
	if get_parent() != on_target:
		if get_parent():
			get_parent().remove_child(self)
		on_target.add_child(self)
	position = offset
	if ground_behind_target:
		on_target.move_child(self, 0)  # desenhado antes do sprite = atrás dele
	_run()


## Acaba agora (toca o "fim"). Pode chamar quantas vezes quiser.
func finish() -> void:
	if ending or not is_inside_tree():
		return
	ending = true
	active = false
	_remove_slow()
	if front:
		front.visible = false
	if ground and _has(ground, end_animation):
		ground.play(end_animation)
		await ground.animation_finished
	_emit_finished()
	queue_free()


## Segundos que faltam no loop.
func get_time_left() -> float:
	return _time_left


func _run() -> void:
	if front:
		front.visible = false
	if slow_from_start:
		_apply_slow()
	started.emit(target)

	if ground and _has(ground, start_animation):
		ground.play(start_animation)
		await ground.animation_finished
		if ending or not is_inside_tree():
			return

	active = true
	_time_left = duration
	_apply_slow()
	if ground and _has(ground, loop_animation):
		ground.play(loop_animation)
	if front and _has(front, loop_animation):
		front.visible = true
		front.play(loop_animation)


func _process(delta: float) -> void:
	if not active or ending:
		return
	if not is_instance_valid(target) or (target.has_method(&"is_dead") and target.is_dead()):
		finish()
		return
	if duration > 0.0:
		_time_left -= delta
		if _time_left <= 0.0:
			finish()


func _exit_tree() -> void:
	_remove_slow()
	_emit_finished()  # sumiu junto com o personagem: quem esperava não fica preso


func _emit_finished() -> void:
	if not _finished_emitted:
		_finished_emitted = true
		finished.emit(target)


func _apply_slow() -> void:
	if slow_percent > 0.0 and is_instance_valid(target):
		SlowComponent.apply(target, self, slow_percent, 0.0, slow_tint)


func _remove_slow() -> void:
	if is_instance_valid(target):
		SlowComponent.remove(target, self)


func _has(sprite: AnimatedSprite2D, animation: StringName) -> bool:
	return sprite.sprite_frames != null and animation != &"" \
		and sprite.sprite_frames.has_animation(animation)
