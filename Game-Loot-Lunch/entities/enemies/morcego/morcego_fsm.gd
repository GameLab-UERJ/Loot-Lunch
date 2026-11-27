extends FiniteStateMachine
class_name MorcegoFSM
## Máquina de estados do MORCEGO (mesmo modelo da FSM do olho voador).
##
##   entrar   -> vem voando da borda da tela até a arena.
##   rondar   -> circula em volta do chef mais próximo (`orbit_time_min..max`).
##   mirar    -> para no ar e pisca os olhos vermelhos: AVISO do ataque (`telegraph_time`).
##   mergulho -> dispara em linha reta para onde o chef ESTAVA (`dive_time`).
##   recuar   -> foge do chef um pouco (`retreat_time`) e volta a rondar.
##   dano     -> levou golpe: sem controle, só o empurrão (knockback) e o pisca.
##   morrer   -> vira fumaça e some.
##   fugir    -> fim da fase: sai voando para fora da tela e some.


var _timer: float = 0.0
var _dive_direction: Vector2 = Vector2.ZERO


func _init() -> void:
	_add_state("entrar")
	_add_state("rondar")
	_add_state("mirar")
	_add_state("mergulho")
	_add_state("recuar")
	_add_state("dano")
	_add_state("morrer")
	_add_state("fugir")


func _ready() -> void:
	await parent.ready
	set_state(states.entrar)


func _state_logic(delta: float) -> void:
	var bat := parent as Morcego
	_timer -= delta
	match state:
		states.entrar:
			bat.find_target()
			bat.fly_towards(bat.arena.get_center() if not is_instance_valid(bat.target) \
				else bat.target.global_position)
		states.rondar:
			bat.find_target()
			bat.fly_towards(bat.orbit_point(delta))
		states.mirar:
			# Treme no ar (o aviso).
			bat.animated_sprite.offset.x = (1.0 if int(_timer * 30.0) % 2 == 0 else -1.0)
		states.mergulho:
			bat.movement_component.move(_dive_direction)
		states.recuar:
			var away: Vector2 = Vector2.UP
			if is_instance_valid(bat.target):
				away = bat.target.global_position.direction_to(bat.global_position)
			bat.movement_component.move(away)
		states.fugir:
			var center: Vector2 = bat.arena.get_center()
			var out_dir: Vector2 = center.direction_to(bat.global_position)
			if out_dir == Vector2.ZERO:
				out_dir = Vector2.UP
			bat.movement_component.move(out_dir)
			if not bat.arena.grow(80.0).has_point(bat.global_position):
				bat.queue_free()


func _get_transition() -> int:
	var bat := parent as Morcego
	match state:
		states.entrar:
			if bat.arena.grow(-8.0).has_point(bat.global_position):
				return states.rondar
		states.rondar:
			if _timer <= 0.0 and is_instance_valid(bat.target):
				return states.mirar
		states.mirar:
			if _timer <= 0.0:
				return states.mergulho
		states.mergulho:
			if _timer <= 0.0:
				return states.recuar
		states.recuar:
			if _timer <= 0.0:
				return states.rondar
		states.dano:
			if _timer <= 0.0:
				return states.recuar
	return -1


func _enter_state(_previous_state: int, new_state: int) -> void:
	var bat := parent as Morcego
	match new_state:
		states.entrar:
			bat.set_cruise()
			bat.animated_sprite.play(&"voar")
		states.rondar:
			bat.set_cruise()
			_timer = randf_range(bat.orbit_time_min, bat.orbit_time_max)
			bat.animated_sprite.play(&"voar")
		states.mirar:
			_timer = bat.telegraph_time
			bat.velocity *= 0.2
			bat.animated_sprite.play(&"mergulho")
		states.mergulho:
			bat.set_dive()
			_timer = bat.dive_time
			_dive_direction = Vector2.DOWN
			if is_instance_valid(bat.target):
				_dive_direction = bat.global_position.direction_to(bat.target.global_position)
			bat.animated_sprite.play(&"mergulho")
		states.recuar:
			bat.set_cruise()
			_timer = bat.retreat_time
			bat.animated_sprite.play(&"voar")
		states.dano:
			_timer = 0.35
			bat.animated_sprite.play(&"dano")
		states.morrer:
			bat.die_effects()
			bat.animated_sprite.play(&"morrer")
			await bat.animated_sprite.animation_finished
			bat.queue_free()
		states.fugir:
			bat.set_dive()
			bat.animated_sprite.play(&"voar")


func _exit_state(state_exited: int) -> void:
	if state_exited == states.mirar:
		(parent as Morcego).animated_sprite.offset.x = 0.0
