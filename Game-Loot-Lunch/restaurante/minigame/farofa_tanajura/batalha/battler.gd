extends Node2D
class_name Battler
## BASE de quem luta na batalha por turnos (ChefBattler, FormigaBattler...).
##
## Cuida só do que é comum: vida (BattleHealthComponent filho), sprite (SheetSprite
## filho "Sprite") e os MOVIMENTOS de cena que toda habilidade usa:
##   await battler.move_to(pos, 0.3)      # corre até a posição
##   await battler.return_home()          # volta para o lugar dele
##   await battler.hop(24, 0.3)           # pulinho (desvia de terremoto, comemora)
##   battler.take_hit(3, direção)         # dano + piscar + empurrão + número subindo
##
## As habilidades (BattleSkill / FormigaSkill) só chamam isso: nenhuma precisa saber
## como cada lutador é desenhado.


signal hit_taken(amount: int)


@export var display_name: String = "Lutador"
## Cor do número de dano que sobe.
@export var damage_color: Color = Color(1.0, 0.45, 0.35)


## Lugar "de descanso" na arena (definido por quem posiciona).
var home_position: Vector2 = Vector2.ZERO
var _flash_tween: Tween


@onready var health: BattleHealthComponent = BattleHealthComponent.find_in(self)
@onready var sprite: SheetSprite = get_node_or_null("Sprite")


func _ready() -> void:
	home_position = global_position


func is_dead() -> bool:
	return health == null or health.is_dead()


## Leva o golpe. Retorna o dano que de fato entrou.
func take_hit(amount: int, from_direction: Vector2 = Vector2.ZERO) -> int:
	var dealt: int = health.damage(amount) if health else 0
	if dealt <= 0:
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -30), "Defendeu!", Color(0.8, 0.9, 1.0))
		return 0
	hit_taken.emit(dealt)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -30), "-%d" % dealt, damage_color)
	flash()
	if from_direction != Vector2.ZERO and sprite:
		var push: Vector2 = from_direction.normalized() * 8.0
		var tween := create_tween()
		tween.tween_property(sprite, "position", push, 0.06)
		tween.tween_property(sprite, "position", Vector2.ZERO, 0.14)
	return dealt


## Cura com número verde subindo.
func heal(amount: int) -> int:
	var gained: int = health.heal(amount) if health else 0
	if gained > 0:
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -34), "+%d" % gained, Color(0.55, 1.0, 0.55))
	return gained


func flash(color: Color = Color(3.0, 3.0, 3.0)) -> void:
	if sprite == null:
		return
	if _flash_tween:
		_flash_tween.kill()
	sprite.modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func move_to(target: Vector2, duration: float, trans: Tween.TransitionType = Tween.TRANS_QUAD) -> void:
	if sprite:
		sprite.play_sheet(&"andar")
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, duration).set_trans(trans).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if sprite:
		sprite.play_sheet(&"idle")


func return_home(duration: float = 0.3) -> void:
	await move_to(home_position, duration)


## Pulinho no lugar (o corpo sobe e desce; a "sombra" fica).
func hop(height: float = 24.0, duration: float = 0.35) -> void:
	if sprite == null:
		return
	var base: Vector2 = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(sprite, "position", base + Vector2(0, -height), duration * 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position", base, duration * 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished


## "Amassa" o sprite (preparando bote, pisada...). Volta ao normal sozinho.
func squash(amount: Vector2 = Vector2(1.25, 0.75), duration: float = 0.25) -> void:
	if sprite == null:
		return
	var base_scale: Vector2 = sprite.scale
	var tween := create_tween()
	tween.tween_property(sprite, "scale", base_scale * amount, duration * 0.6)
	tween.tween_property(sprite, "scale", base_scale, duration * 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


## Vira o sprite para olhar para `point`. `faces_left` = a arte original olha para a esquerda.
func face(point: Vector2, faces_left: bool = false) -> void:
	if sprite == null or is_equal_approx(point.x, global_position.x):
		return
	var looking_left: bool = point.x < global_position.x
	sprite.flip_h = looking_left != faces_left
