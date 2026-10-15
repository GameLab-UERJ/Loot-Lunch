extends AnimatedSprite2D
class_name RegrowSprite
## Visual de algo que é COLHIDO e depois REGENERA (pé de cogumelo, raiz de espeto,
## no futuro árvore de fruta, horta...). Só cuida da animação; quem decide QUANDO
## colher e quanto tempo dura a regeneração é o dono (a estação).
##
## Animações esperadas no SpriteFrames (nomes configuráveis no Inspector):
##   idle         (loop)      pronto para colher
##   corte        (sem loop)  toca na hora da colheita, termina no toco
##   regenerando  (sem loop)  cresce de volta durante o cooldown
##   vazio        (1 quadro)  toco parado, usado se não houver `regenerando`
##
## Uso pelo dono:
##   sprite.play_harvest(cooldown_em_segundos)  # corte -> regenerando, termina junto com o cooldown
##   sprite.play_ready()                        # fim do cooldown, volta para idle
##
## A velocidade de `regenerando` é calculada sozinha a partir do cooldown, então
## mudar o tempo de regeneração da estação NÃO exige mexer no .tres.


signal harvest_finished
signal regrow_finished


@export var idle_animation: StringName = &"idle"
@export var harvest_animation: StringName = &"corte"
@export var regrow_animation: StringName = &"regenerando"
@export var empty_animation: StringName = &"vazio"


var _regrow_time: float = 0.0
var _is_harvesting: bool = false


func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	play_ready()


## Volta para o estado "pronto para colher".
func play_ready() -> void:
	_is_harvesting = false
	speed_scale = 1.0
	_play_if_exists(idle_animation)


## Toca o corte e, em seguida, a regeneração esticada para durar o resto de `total_time`.
func play_harvest(total_time: float) -> void:
	_is_harvesting = true
	speed_scale = 1.0
	if _has(harvest_animation):
		_regrow_time = maxf(total_time - _length_of(harvest_animation), 0.05)
		play(harvest_animation)
	else:
		_regrow_time = maxf(total_time, 0.05)
		_start_regrow()


func _start_regrow() -> void:
	if not _has(regrow_animation):
		speed_scale = 1.0
		_play_if_exists(empty_animation)
		return
	speed_scale = _length_of(regrow_animation) / _regrow_time
	play(regrow_animation)


func _on_animation_finished() -> void:
	if not _is_harvesting:
		return
	if animation == harvest_animation:
		harvest_finished.emit()
		_start_regrow()
	elif animation == regrow_animation:
		regrow_finished.emit()


## Duração da animação em segundos com speed_scale = 1.
func _length_of(anim: StringName) -> float:
	var fps: float = sprite_frames.get_animation_speed(anim)
	if fps <= 0.0:
		return 0.0
	var total: float = 0.0
	for i in sprite_frames.get_frame_count(anim):
		total += sprite_frames.get_frame_duration(anim, i)
	return total / fps


func _has(anim: StringName) -> bool:
	return sprite_frames != null and sprite_frames.has_animation(anim)


func _play_if_exists(anim: StringName) -> void:
	if _has(anim):
		play(anim)
