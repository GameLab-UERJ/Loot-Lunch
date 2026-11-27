extends Enemy
class_name Morcego
## MORCEGO: inimigo voador das fases do Reino Caveira (a partir da 1-2).
##
## Mesmo modelo dos outros inimigos (Character + FSM + componentes):
##   - `hp` / `take_damage` do Character (a panela do chef e a Brasa usam HitboxComponent);
##   - MovementComponent para voar (acelera até `max_speed`, o Character freia sozinho);
##   - HitboxComponent "Mordida": encostar no CHEF tira vida (só o grupo "chefs": a Brasa
##     é fogo, não leva mordida);
##   - MorcegoFSM decide o comportamento (ver o script dela).
##
## Comportamento: entra voando pela borda da tela, RONDA o chef mais próximo, PISCA os
## olhos (aviso) e dá um MERGULHO em linha reta. Acertando ou não, RECUA e volta a rondar.
## Levou golpe: é empurrado (knockback), pisca e recua. Vida 0: vira fumaça.
##
## Ele voa: não colide com nada (máscara 0) e fica preso dentro de `arena` depois que entra.


## Grupo de todos os morcegos vivos (o BatSpawner conta por aqui).
const GROUP: StringName = &"morcegos"
## Grupo genérico de inimigos (a panela e a Brasa só acertam quem está nele).
const ENEMY_GROUP: StringName = &"inimigos"
## O som de "crunch" (o mesmo do golpe do Player) começa em 1,1 s do arquivo.
const HURT_SFX_FROM: float = 1.1


## Morreu (já começou a virar fumaça).
signal defeated(morcego: Morcego)


@export_group("Voo")
## Velocidade rondando / recuando.
@export var cruise_speed: int = 70
@export var cruise_acceleration: int = 16
## Velocidade do mergulho.
@export var dive_speed: int = 190
@export var dive_acceleration: int = 60
## Distância do chef enquanto ronda.
@export var orbit_radius: float = 52.0
## Quanto a órbita gira por segundo (radianos).
@export var orbit_speed: float = 1.4
## Área onde o morcego fica preso depois de entrar (coordenadas globais).
@export var arena: Rect2 = Rect2(16, 16, 608, 328)

@export_group("Ataque")
## Tempo rondando antes de atacar (sorteado entre os dois).
@export var orbit_time_min: float = 2.2
@export var orbit_time_max: float = 4.0
## Aviso antes do mergulho (olhos piscando, parado no ar).
@export var telegraph_time: float = 0.45
## Duração máxima do mergulho.
@export var dive_time: float = 0.6
## Quanto tempo foge depois de atacar ou apanhar.
@export var retreat_time: float = 0.7

@export_group("Visual")
## Balanço do voo (px) e velocidade do balanço.
@export var bob_height: float = 2.0
@export var bob_speed: float = 7.0


var target: Node2D = null
var _orbit_angle: float = 0.0
var _bob_time: float = 0.0
var _entered_arena: bool = false
var _fleeing: bool = false

@onready var state_machine: MorcegoFSM = $FiniteStateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var movement_component: MovementComponent = $MovementComponent
@onready var flip_sprite_component: FlipSpriteComponent = $FlipSpriteComponent
@onready var bite_hitbox: HitboxComponent = $Mordida
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var wing_flap_sfx: AudioStreamPlayer2D = $WingFlapSfx
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSfx


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(ENEMY_GROUP)
	_orbit_angle = randf() * TAU
	_bob_time = randf() * TAU
	set_cruise()
	animated_sprite.frame_changed.connect(_on_frame_changed)


func _process(delta: float) -> void:
	_bob_time += delta * bob_speed
	animated_sprite.offset.y = sin(_bob_time) * bob_height
	if is_instance_valid(target):
		flip_sprite_component.node_to_face = target


func _physics_process(delta: float) -> void:
	super(delta)
	if _fleeing:
		return
	if not _entered_arena:
		_entered_arena = arena.has_point(global_position)
	else:
		global_position = global_position.clamp(arena.position, arena.end)


# --- Usado pela FSM ------------------------------------------------------------

func set_cruise() -> void:
	movement_component.max_speed = cruise_speed
	movement_component.acceleration = cruise_acceleration


func set_dive() -> void:
	movement_component.max_speed = dive_speed
	movement_component.acceleration = dive_acceleration


func fly_towards(point: Vector2) -> void:
	movement_component.move(point - global_position)


## Chef vivo mais próximo (ou null).
func find_target() -> Node2D:
	var best: Node2D = null
	var best_dist: float = INF
	for node in get_tree().get_nodes_in_group(Chef.GROUP):
		var chef := node as Node2D
		if chef == null or not chef.visible:
			continue
		if chef.has_method("is_dead") and chef.is_dead():
			continue
		var dist: float = global_position.distance_squared_to(chef.global_position)
		if dist < best_dist:
			best_dist = dist
			best = chef
	target = best
	return best


## Ponto da órbita em volta do alvo (ou do centro da arena, sem alvo).
func orbit_point(delta: float) -> Vector2:
	_orbit_angle = wrapf(_orbit_angle + orbit_speed * delta, 0.0, TAU)
	var center: Vector2 = target.global_position if is_instance_valid(target) else arena.get_center()
	return center + Vector2(cos(_orbit_angle), sin(_orbit_angle) * 0.6) * orbit_radius


func is_dead() -> bool:
	return hp <= 0


## Fim da fase: para de atacar e vai embora voando.
func flee() -> void:
	if is_dead() or _fleeing:
		return
	_fleeing = true
	bite_hitbox.set_deferred("monitoring", false)
	state_machine.set_state(state_machine.states.fugir)


func is_fleeing() -> bool:
	return _fleeing


func die_effects() -> void:
	become_invulnerable()
	bite_hitbox.set_deferred("monitoring", false)
	body_shape.set_deferred("disabled", true)
	defeated.emit(self)


# --- Sinais --------------------------------------------------------------------

func _on_got_hurt() -> void:
	hurt_sfx.pitch_scale = randf_range(1.1, 1.3)
	hurt_sfx.play(HURT_SFX_FROM)
	if not _fleeing:
		state_machine.set_state(state_machine.states.dano)


func _on_died() -> void:
	hurt_sfx.pitch_scale = 0.8
	hurt_sfx.play(HURT_SFX_FROM)
	state_machine.set_state(state_machine.states.morrer)


func _on_bite_hit() -> void:
	# Mordeu: recua para não ficar grudado no chef.
	if state_machine.state == state_machine.states.mergulho:
		state_machine.set_state(state_machine.states.recuar)


func _on_frame_changed() -> void:
	if animated_sprite.animation == &"voar" and animated_sprite.frame == 0 and randf() < 0.35:
		wing_flap_sfx.pitch_scale = randf_range(0.95, 1.2)
		wing_flap_sfx.play()
