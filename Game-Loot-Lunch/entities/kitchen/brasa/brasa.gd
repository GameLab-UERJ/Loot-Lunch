extends Character
class_name Brasa
## BRASA: a churrasqueira que é uma CHAMA VIVA e anda pela cozinha (2º jogador).
##
## Ela faz TUDO que a churrasqueira faz porque, por dentro, ela É a churrasqueira:
## o filho `Churrasqueira` é uma `CookingStation` normal (mesmo script, mesmas receitas
## `assar_*.tres`, mesmas 2 bocas `CookingSlot`, mesma barrinha, balão e labareda
## aleatória). A Brasa só acrescenta as PERNAS: é um `Character` (CharacterBody2D)
## com InputComponent + MovementComponent, igual ao chef, e leva a estação junto.
##
##   chef (ESPAÇO) com espetinho cru na mão perto dela -> espetinho entra numa "mão"
##   de fogo -> assa com o tempo (cru -> no ponto -> torrado -> queima) ->
##   chef (ESPAÇO, mão vazia) tira; R joga fora. A Brasa pode andar o tempo todo.
##
## Quem desenha o humor dela (parada / andando / assando / alerta / risada) é a
## `BrasaFSM`, que só OLHA a velocidade e as bocas da estação.
##
## Controles: as ações do `InputComponent` (por padrão `brasa_up/down/left/right` = setas).
## `can_control = false` deixa ela parada (para IA, cutscene ou fase com 1 jogador).


## Grupo de todas as brasas (útil para fases, IA, magias...).
const GROUP: StringName = &"brasas"


@export var can_control: bool = true
## Toca a animação "surgir" (brasinha no chão que vira chama) ao entrar na cena.
@export var play_intro: bool = true

@export_group("Sprite")
## Para qual lado a ARTE olha sem espelhar. A animação "andar" foi desenhada indo para
## a DIREITA, então fica desligado.
@export var sprite_faces_left: bool = false


var facing_direction: Vector2 = Vector2.RIGHT


@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var state_machine: BrasaFSM = %FiniteStateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
## A churrasqueira de verdade (CookingStation) que a Brasa carrega.
@onready var station: CookingStation = %Churrasqueira


func _ready() -> void:
	add_to_group(GROUP)
	if not input_component.direction_changed.is_connected(_on_input_component_direction_changed):
		input_component.direction_changed.connect(_on_input_component_direction_changed)


func _process(_delta: float) -> void:
	if not is_zero_approx(facing_direction.x):
		var looking_left: bool = facing_direction.x < 0
		animated_sprite.flip_h = looking_left != sprite_faces_left


## Pode ler o teclado agora? (atordoada por magia = não anda)
func can_move() -> bool:
	return can_control and not StunComponent.is_active_on(self)


func is_moving() -> bool:
	return velocity.length() > state_machine.move_threshold


func _on_input_component_direction_changed(new_movement_direction: Vector2) -> void:
	# Mesmas regras do chef: confusa = setas invertidas.
	new_movement_direction = ConfusionComponent.transform_direction(self, new_movement_direction)
	movement_component.move(new_movement_direction)
	if new_movement_direction != Vector2.ZERO:
		facing_direction = new_movement_direction.normalized()
