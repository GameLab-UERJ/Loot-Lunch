extends Node2D
class_name Panela
## PANELA: a arma do chef. Mesma dinâmica da espada do Player:
##   - SACADA, ela fica na mão do chef apontando para a mira (o mouse), girando o nó
##     inteiro e espelhando quando a mira está à esquerda (igual a `Player.sword`);
##   - o golpe é a animação "golpe" do AnimationPlayer (igual ao "attack" da espada), que
##     liga a colisão do HitboxComponent só por um instante e mostra o rastro;
##   - o HitboxComponent acerta quem tem `take_damage` (morcegos e outros inimigos).
##
## GUARDADA, ela some. Quem decide sacar, guardar e bater é a `PanelaAbility`.


signal drawn
signal holstered
signal swung
## Acertou alguém (vem do HitboxComponent).
signal hit


var _drawn: bool = false

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var swing_sfx: AudioStreamPlayer2D = $SwingSfx
@onready var draw_sfx: AudioStreamPlayer2D = $DrawSfx


func _ready() -> void:
	visible = false
	hitbox.hit.connect(hit.emit)


## Aponta a panela (e o golpe) para `direction`. Chamado todo quadro enquanto sacada.
func aim(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	direction = direction.normalized()
	rotation = direction.angle()
	# Mira à esquerda: espelha para a panela continuar "de pé" (como a espada do Player).
	scale.y = -1.0 if direction.x < 0.0 else 1.0
	hitbox.knockback_direction = direction


func is_drawn() -> bool:
	return _drawn


## Saca: a panela aparece na mão.
func draw_weapon() -> void:
	if _drawn:
		return
	_drawn = true
	visible = true
	animation_player.play(&"RESET")
	animation_player.advance(0.0)
	draw_sfx.pitch_scale = randf_range(1.3, 1.5)
	draw_sfx.play()
	drawn.emit()


## Guarda: cancela o golpe (se tiver) e some.
func holster() -> void:
	if not _drawn:
		return
	cancel()
	_drawn = false
	visible = false
	holstered.emit()


## Bate na direção da mira atual. Retorna a duração do golpe (s). Precisa estar sacada.
func swing() -> float:
	if not _drawn:
		return 0.0
	animation_player.stop()
	animation_player.play(&"golpe")
	swing_sfx.pitch_scale = randf_range(0.9, 1.1)
	swing_sfx.play()
	swung.emit()
	return animation_player.get_animation(&"golpe").length


func is_swinging() -> bool:
	return animation_player.is_playing() and animation_player.current_animation == &"golpe"


## Interrompe o golpe no meio (o chef levou dano...). Continua sacada.
func cancel() -> void:
	animation_player.play(&"RESET")
	animation_player.advance(0.0)
	animation_player.stop()
