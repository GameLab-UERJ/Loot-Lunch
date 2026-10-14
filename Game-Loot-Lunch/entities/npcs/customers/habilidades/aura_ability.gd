extends CustomerAbility
class_name AuraAbility
## MAGIA DE AURA genérica: gruda uma StatusAura no chef (símbolo de bruxaria da Mandy,
## "desorientado" do Johnny...). A aura é uma CENA (`aura_scene`); esta magia só escolhe
## o alvo, gruda e, se `channel` estiver ligado, fica "conjurando" enquanto a aura dura.
##
## Não tem projétil nem colisão: é impossível de desviar (nem com dash).


signal aura_attached(aura: StatusAura)


@export_group("Aura")
@export var aura_scene: PackedScene
## Segundos da aura no alvo. < 0 = usa o `duration` da cena.
@export var duration: float = 4.0
## A cliente fica conjurando (ocupada) até a aura acabar. Se ela for interrompida
## (ex.: foi atendida), a aura acaba junto.
@export var channel: bool = true
## Se o alvo já tem uma aura desta magia, só renova o tempo (não empilha).
@export var refresh_if_active: bool = true


var _current: StatusAura = null


func _perform(target: Node2D) -> void:
	if aura_scene == null or target == null:
		return

	if refresh_if_active and is_instance_valid(_current) and _current.target == target \
			and not _current.ending:
		_current.duration = duration if duration >= 0.0 else _current.duration
		_current._time_left = _current.duration
		return

	var aura: StatusAura = StatusAura.attach(aura_scene, target, duration)
	if aura == null:
		return
	_current = aura
	aura_attached.emit(aura)

	if channel:
		await aura.finished


func _on_interrupt() -> void:
	super._on_interrupt()
	if channel and is_instance_valid(_current):
		_current.finish()
