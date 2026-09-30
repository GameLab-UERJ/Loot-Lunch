extends AnimatedSprite2D
class_name TurnToDust
## FINALIZAÇÃO "VIRA PÓ": o personagem leva o choque, vira um montinho de cinzas e morre,
## não importa quanta vida tinha (nuvem do Johnny no chef que já estava confuso).
##
##     TurnToDust.apply(chef, arte_vira_po)
##
## O que acontece:
##   1. esconde o personagem (`visible = false`) e toca a arte no lugar dele, no mundo;
##   2. mata o personagem (ignora invencibilidade);
##   3. as cinzas ficam no chão (último quadro) até ele reviver (ou `remains_time`).
## Quando o personagem revive, as cinzas somem sozinhas (o chef volta a ficar visível no
## `_revive`).


signal finished(victim: Node2D)


## Segundos que as cinzas ficam no chão. 0 = até o personagem reviver.
@export var remains_time: float = 0.0


var victim: Node2D = null

var _time: float = 0.0


static func apply(target: Node2D, animation: SheetAnimation, world: Node = null) -> TurnToDust:
	if target == null or not is_instance_valid(target) or animation == null:
		return null
	if target.has_method(&"is_dead") and target.is_dead():
		return null
	if world == null:
		world = target.get_parent()

	var effect := TurnToDust.new()
	effect.name = "ViraPo"
	effect.victim = target
	effect.sprite_frames = animation.build_frames()
	effect.sprite_frames.set_animation_loop(SheetAnimation.ANIMATION_NAME, false)
	effect.scale = animation.scale
	effect.z_index = animation.z_index
	world.add_child(effect)
	effect.global_position = target.global_position + animation.offset
	effect.play(SheetAnimation.ANIMATION_NAME)
	effect.animation_finished.connect(func() -> void: effect.finished.emit(target),
		CONNECT_ONE_SHOT)

	target.visible = false
	kill(target)
	return effect


## Mata `target` na hora, mesmo invencível/invulnerável.
static func kill(target: Node) -> void:
	if target.has_method(&"interrupt_abilities"):
		target.interrupt_abilities()
	if target.has_method(&"kill"):
		target.kill()
		return
	if not target.has_method(&"take_damage"):
		return
	if &"is_invincible" in target:
		target.is_invincible = false
	if &"is_invulnerable" in target:
		target.is_invulnerable = false
	var hp_left: int = int(target.get(&"hp")) if &"hp" in target else 999
	target.take_damage(maxi(hp_left, 1), Vector2.ZERO, 0)


func _process(delta: float) -> void:
	if not is_instance_valid(victim):
		queue_free()
		return
	# Reviveu: as cinzas somem (o chef aparece de novo no _revive).
	if victim.has_method(&"is_dead") and not victim.is_dead():
		victim.visible = true
		queue_free()
		return
	if remains_time > 0.0 and not is_playing():
		_time += delta
		if _time >= remains_time:
			queue_free()
