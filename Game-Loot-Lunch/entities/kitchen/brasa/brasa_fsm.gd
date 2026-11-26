extends FiniteStateMachine
class_name BrasaFSM
## Máquina de estados da BRASA. Lê o teclado (como a ChefFSM) e escolhe a animação.
## Não muda nenhuma regra do cozimento: só olha a velocidade e as bocas da estação.
##
## Estados (= animações do AnimatedSprite2D, em `brasa_frames.tres`):
##   surgir   -> brasinha no chão vira chama e abre os olhos.        (uma vez, no início)
##   idle     -> parada, sem espetinho. Chama calminha, pisca.      (loop)
##   andar    -> andando. Inclina, dá pulinhos e deixa fagulhas.    (loop)
##   assando  -> parada com espetinho no fogo. Chama maior, feliz.  (loop)
##   alerta   -> algum espetinho está TORRADO: vai queimar!         (loop, vale andando também)
##   risada   -> um espetinho queimou e sumiu. Ri do jogador.       (uma vez)
##
## Prioridade: surgir/risada vão até o fim > alerta > andar > assando > idle.


const ANIMATIONS: Dictionary = {
	"surgir": &"surgir",
	"idle": &"idle",
	"andar": &"andar",
	"assando": &"assando",
	"alerta": &"alerta",
	"risada": &"risada",
}


## Sprite animado da Brasa. Se vazio, usa o filho "AnimatedSprite2D" do pai.
@export var sprite: AnimatedSprite2D
## Estação observada. Se vazio, usa o filho "Churrasqueira" do pai.
@export var station: CookingStation
## Acima desta velocidade (px/s) a Brasa está "andando".
@export var move_threshold: float = 10.0


func _init() -> void:
	_add_state("surgir")
	_add_state("idle")
	_add_state("andar")
	_add_state("assando")
	_add_state("alerta")
	_add_state("risada")


func _ready() -> void:
	if sprite == null:
		sprite = parent.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if station == null:
		station = parent.get_node_or_null("Churrasqueira") as CookingStation
	if station:
		station.item_vanished.connect(_on_item_vanished)
	if parent.play_intro and _has_animation(states.surgir):
		set_state(states.surgir)
	else:
		set_state(get_resting_state())


## Estados em que a Brasa pode andar.
func is_free() -> bool:
	return active and state != states.surgir


func _state_logic(_delta: float) -> void:
	if not is_free() or not parent.can_move():
		return
	parent.input_component.get_input()


func _get_transition() -> int:
	# Surgir e risada vão até o último quadro antes de voltar ao normal.
	if (state == states.surgir or state == states.risada) and sprite and sprite.is_playing():
		return -1
	var resting: int = get_resting_state()
	return resting if resting != state else -1


## Estado "de descanso" agora (sem contar surgir/risada).
func get_resting_state() -> int:
	if _has_burnt_item():
		return states.alerta
	if parent.velocity.length() > move_threshold:
		return states.andar
	if station and station.get_count() > 0:
		return states.assando
	return states.idle


func _enter_state(_previous_state: int, new_state: int) -> void:
	if sprite == null:
		return
	if not _has_animation(new_state):
		new_state = states.idle
		if not _has_animation(new_state):
			return
	sprite.play(ANIMATIONS[states.find_key(new_state)])
	sprite.frame = 0


func _has_animation(target_state: int) -> bool:
	if sprite == null or sprite.sprite_frames == null:
		return false
	return sprite.sprite_frames.has_animation(ANIMATIONS[states.find_key(target_state)])


func _has_burnt_item() -> bool:
	if station == null:
		return false
	for slot in station.get_slots():
		if slot.is_occupied() and slot.get_stage() == CookingSlot.Stage.BURNT:
			return true
	return false


func _on_item_vanished(_slot: CookingSlot, _recipe: CookingRecipe) -> void:
	if _has_animation(states.risada):
		set_state(states.risada)
