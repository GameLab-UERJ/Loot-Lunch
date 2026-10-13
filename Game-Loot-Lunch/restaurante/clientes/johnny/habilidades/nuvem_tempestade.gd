extends Summon
class_name StormCloud
## NUVEM DE TEMPESTADE (surge no centro do raio supremo do Johnny).
##
##   surgir -> andar (persegue o chef devagar) -> encostou -> descarga (raio na cabeça)
##
## A descarga acerta no quadro `strike_frame` quem ainda estiver embaixo (`strike_radius`):
##   - chef normal          -> GRANDE CHOQUE + CONFUSO por `confusion_time` s (setas invertidas);
##   - chef que JÁ ESTAVA confuso -> VIRA PÓ (finalizado).
## Depois da descarga a nuvem se desfaz (a própria arte da descarga termina sumindo).
## Chef dando dash (invulnerável) não é alvo da descarga: a nuvem espera ele parar.
##
## Voa por cima de tudo (sem colisão com paredes/balcão). Dança ("comemorar") quando
## alguém pede dança (demoninho da Mandy grudado) ou quando não sobra chef livre.


signal discharged(target: Node2D, hit: bool)
signal chef_confused(target: Node2D)
signal chef_finalized(target: Node2D)


@export_group("Descarga")
## Quadro da "descarga" em que o raio toca o chão (0 = primeiro).
@export var strike_frame: int = 2
## Distância (centro a centro) que ainda conta como "embaixo da nuvem" no quadro do raio.
@export var strike_radius: float = 20.0
## Segundos de confusão (setas invertidas).
@export var confusion_time: float = 10.0
## Arte em cima da cabeça enquanto está confuso.
@export var confusion_visual: SheetAnimation
## Efeito que toca UMA vez no chef quando leva a descarga.
@export var shock_effect: SheetAnimation
## Arte do chef virando pó (finalização).
@export var dust_animation: SheetAnimation

@export_group("Animações da nuvem")
@export var spawn_animation: StringName = &"surgir"
@export var discharge_animation: StringName = &"descarga"


var discharging: bool = false


func _ready() -> void:
	spawn_pop = false  # a nuvem tem arte própria de surgir
	super._ready()
	if has_animation(spawn_animation):
		busy = true
		play_animation(spawn_animation)
		await animated_sprite.animation_finished
		if not is_inside_tree() or despawning:
			return
		busy = false
		celebrating = false
		play_animation(walk_animation)


func _on_reached(reached: Node2D) -> void:
	if discharging or reached == null:
		return
	if reached.get(&"is_invulnerable") == true:
		return  # dando dash: espera
	_discharge(reached)


func _discharge(victim: Node2D) -> void:
	discharging = true
	busy = true
	velocity = Vector2.ZERO
	if animated_sprite:
		animated_sprite.modulate.a = 1.0

	var hit: bool = false
	if has_animation(discharge_animation):
		play_animation(discharge_animation)
		while animated_sprite.is_playing() and animated_sprite.frame < strike_frame:
			await animated_sprite.frame_changed
		if not is_inside_tree():
			return
		hit = _apply_discharge(victim)
		if animated_sprite.is_playing():
			await animated_sprite.animation_finished
	else:
		hit = _apply_discharge(victim)

	discharged.emit(victim, hit)
	despawned.emit()
	queue_free()


## Aplica o choque se o chef ainda estiver embaixo. Retorna se acertou.
func _apply_discharge(victim: Node2D) -> bool:
	if not CaptureComponent.is_available_target(victim):
		return false
	if victim.get(&"is_invulnerable") == true:
		return false
	if global_position.distance_to(victim.global_position) > strike_radius:
		return false

	if ConfusionComponent.is_active_on(victim):
		# Segunda descarga no chef confuso: vira pó.
		TurnToDust.apply(victim, dust_animation)
		chef_finalized.emit(victim)
		return true

	SheetAnimation.spawn_once(shock_effect, null, victim.global_position, victim)
	# Fonte = a arte do confuso: nuvens diferentes renovam o mesmo status.
	ConfusionComponent.apply(victim, confusion_visual if confusion_visual else &"storm_cloud",
			confusion_time, confusion_visual)
	chef_confused.emit(victim)
	return true
